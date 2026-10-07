#!/usr/bin/env bash
# PreToolUse guard for Bash: `git commit` inside a ticket worktree.
#
# The /work pipeline records in the ticket's state file,
# work-log/<repo>/<TICKET>/state.md, whether the AI may commit per verified
# step (`commits: auto`, the default it writes when it creates the file) or
# Tobias commits himself (`commits: manual`, set per ticket with
# `/work <T> commits manual` or `manual` in a gate answer).
# This hook turns that record into a mechanical rule that holds in every
# permission mode, auto mode included (the classifier would otherwise wave a
# routine commit through):
#
#   cwd under $WT_ROOT, state.md says commits: auto    -> allow (no prompt)
#   cwd under $WT_ROOT, state.md says commits: manual  -> deny
#   cwd under $WT_ROOT, no state.md for the ticket     -> no opinion (normal rules)
#   anywhere else                                      -> no opinion
#
# An "allow" from a PreToolUse hook bypasses the permission rules and the
# classifier for the WHOLE command string, so it is only given when the
# command is exactly one plain `git commit …` (no `&&`, `;`, `|`, `$(`,
# backticks, redirects, newlines). `--amend` and `--no-verify` always ask.
#
# Version-controlled in the dotfiles repo and symlinked to
# ~/.claude/hooks/commit-guard.sh via mkOutOfStoreSymlink (see
# home-manager/packages/commons.nix).
set -euo pipefail

CODE_DIR="${WT_CODE_DIR:-$HOME/code}"
WT_ROOT="${WT_ROOT:-$CODE_DIR/worktrees}"
WORK_LOG="${WORK_LOG:-$HOME/code/knowledge/work-log}"

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')

# Only commits are our business. Word-boundary match so `git commit-tree` or a
# commit message mentioning "commit" elsewhere does not trigger.
printf '%s' "$command" | grep -Eq '(^|[^[:alnum:]_])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit([^[:alnum:]_-]|$)' || exit 0

decide() {
  jq -n --arg d "$1" --arg reason "$2" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: $d,
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

if printf '%s' "$command" | grep -Eq '(^|[[:space:]])--amend([[:space:]]|$)'; then
  decide ask "commit-guard.sh: \`git commit --amend\` rewrites history — confirm."
fi
if printf '%s' "$command" | grep -Eq '(^|[[:space:]])(--no-verify|-n)([[:space:]]|$)'; then
  decide ask "commit-guard.sh: \`--no-verify\` skips the repo's hooks — confirm."
fi

# A `git -C <dir> commit` names its own directory; otherwise the cwd counts.
dir=$(printf '%s' "$command" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]]+)[[:space:]]+commit.*/\1/p' | head -1)
dir=${dir:-$cwd}
dir=${dir/#\~/$HOME}

case "$dir" in
  "$WT_ROOT"/*) ;;
  *) exit 0 ;;   # not a ticket worktree: normal permission rules apply
esac

branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)
ticket=$(printf '%s' "$branch" | grep -oE '[A-Z]+-[0-9]+' | tail -1 || true)
[[ -n "$ticket" ]] || exit 0

main=$(dirname "$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)") || exit 0
repo=$(basename "$main")
state="$WORK_LOG/$repo/$ticket/state.md"
[[ -f "$state" ]] || exit 0

mode=$(sed -nE 's/^commits:[[:space:]]*([a-z]+).*/\1/p' "$state" | head -1)
case "$mode" in
  manual) decide deny "commit-guard.sh: $ticket has commits: manual — Tobias commits himself. Stage the step (git add) and record the commit line in state.md ## Commits." ;;
  auto) ;;
  *) exit 0 ;;
esac

# allow only a single plain commit command: anything composed goes to the
# normal rules (push, curl, subshells must never ride on this allow)
if printf '%s' "$command" | grep -Eq '(&&|\|\||[;|<>`]|\$\(|\$\{)' || [[ "$command" == *$'\n'* ]]; then
  exit 0
fi
printf '%s' "$command" | grep -Eq '^[[:space:]]*git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit([[:space:]]|$)' || exit 0

decide allow "commit-guard.sh: $ticket has commits: auto in state.md."
