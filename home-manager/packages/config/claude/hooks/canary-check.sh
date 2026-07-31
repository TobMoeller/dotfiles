#!/usr/bin/env bash
# Stop hook: context-degradation canary.
#
# CLAUDE.md carries one trivial, deeply-buried instruction ("start every response
# with <marker>"). Long sessions degrade instruction-following *silently* — the
# model drops small, deeply-nested rules a turn or two before it starts getting
# real things wrong. So the marker going missing is an early warning, not a
# cosmetic slip. (Technique: agentsroom.dev, "canary trick".)
#
# This hook reads the session transcript after each assistant turn and warns when
# the last response did not start with the marker. It only warns — it never
# blocks the turn or forces a retry, because the useful reaction is human:
# re-check the last few answers, then /clear and re-brief.
#
# Version-controlled in the dotfiles repo and symlinked to
# ~/.claude/hooks/canary-check.sh via mkOutOfStoreSymlink (see
# home-manager/packages/commons.nix), so edits take effect immediately.
#
# The marker must match the one in packages/config/claude/CLAUDE.md. Override
# both by exporting CLAUDE_CANARY and editing that file.
set -euo pipefail

canary="${CLAUDE_CANARY:-🐤}"

input=$(cat)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // ""')
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

# One user turn is many transcript entries: every content block gets its own
# JSONL line, and a turn spans several API responses interleaved with tool_result
# entries. So the canary sits at the start of the *first* text block after the
# user's prompt — never in the closing summary text, which is what the naive
# "last assistant text" reading picks up (that produced false alarms).
#
# Hence: find the last real user prompt (not a tool_result, not isMeta, not an
# injected <system-reminder>/<local-command-stdout> entry), then take the first
# non-empty assistant text after it. Main chain only — subagents (isSidechain)
# never see CLAUDE.md's canary rule.
#
# First line of output = turn count (real user prompts), rest = that text.
parsed=$(jq -rs '
  def content: (.message.content // []);
  def texts:
    (content) as $c
    | if ($c | type) == "string" then [$c]
      else [ $c[] | select(.type == "text") | .text ]
      end;
  def is_prompt:
    .type == "user"
    and (.isMeta != true)
    and (.isCompactSummary != true)
    and ((content | type) == "string"
         or ([ content[] | select(.type == "tool_result") ] | length) == 0)
    and ([ texts[]
           | select(test("^\\s*<(local-command-stdout|local-command-stderr|system-reminder)") | not)
           | select(test("^\\s*\\[Request interrupted") | not)
           | select(length > 0) ] | length) > 0;

  [ .[] | select(.isSidechain != true) | select(.type == "assistant" or is_prompt) ] as $chain
  | ( [ $chain | to_entries[] | select(.value | is_prompt) | .key ] | last // -1 ) as $start
  | ( [ $chain[$start + 1:][]
        | select(.type == "assistant")
        | texts[] | select(length > 0) ] | first // "" ) as $text
  | ( [ $chain[] | select(is_prompt) ] | length ) as $turns
  | "\($turns)\n\($text)"
' "$transcript")

# No newline at all means jq found no text for this turn (tool-only turn, or the
# user's prompt is the last entry) — command substitution ate the trailing \n.
case "$parsed" in
  *$'\n'*) ;;
  *) exit 0 ;;
esac
turns=${parsed%%$'\n'*}
last_text=${parsed#*$'\n'}
[ -n "$last_text" ] || exit 0

trimmed="${last_text#"${last_text%%[![:space:]]*}"}"
case "$trimmed" in
  "$canary"*) exit 0 ;;   # canary alive
esac

jq -n --arg msg "⚠️  Canary \"$canary\" fehlt in der letzten Antwort (Turn $turns).
Instruction-following lässt nach — das kommt typischerweise ein bis zwei Züge vor
echten Fehlern. Empfehlung: die letzten 2–3 Antworten misstrauisch gegenprüfen,
dann /clear und mit einem knappen Briefing neu starten (Ziel, aktuelle Datei,
bereits getroffene Entscheidungen)." '{systemMessage: $msg}'

exit 0
