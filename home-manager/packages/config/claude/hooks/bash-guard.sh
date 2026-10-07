#!/usr/bin/env bash
# PreToolUse guard for Bash.
#
# Catches dangerous words ANYWHERE in the command string (not just at the
# start of a parsed sub-command, which is all the settings.json permission
# patterns can see). Version-controlled in the dotfiles repo and symlinked to
# ~/.claude/hooks/bash-guard.sh via mkOutOfStoreSymlink (see
# home-manager/packages/commons.nix).
#
#   sudo                                   -> deny  (hard block)
#   git push --force / -f / +ref           -> deny  (history rewrite on the remote)
#   db:wipe                                -> deny  (drops a database, in any stack)
#   migrate:fresh                          -> ask   (drops and rebuilds a database;
#                                                    routine for a worktree test DB,
#                                                    fatal elsewhere — Tobias decides)
#   git push (any spelling)                -> ask   (the acceptance gate; prefix
#                                                    rules miss `git -C … push`)
#   docker compose down -v/--volumes       -> ask   (deletes a stack's data)
#
# The (^|[^[:alnum:]_])WORD([^[:alnum:]_]|$) boundary matches the word in any
# position (after a space, '(', '&', ';', '|', or string start/end) while not
# matching e.g. `pseudonym`. Character classes (not \b) keep this
# portable across GNU and BSD grep. Best-effort only: literal-token obfuscation
# (variable indirection, base64, unicode) can still slip past.
#
# Heredoc bodies that are plain data are not scanned: `cat >> note.md <<'EOF'`,
# `tee`, `git commit -F - <<'EOF'`, with a quoted delimiter, nothing chained on
# the heredoc line and the heredoc closing the command. A note or commit message that mentions
# sudo or migrate:fresh is text, not a command. A body fed to anything else
# (`bash <<EOF`, `python3 - <<EOF`, a pipe) or followed by more commands is
# scanned as before.
set -euo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

strip_data_heredoc() {
  # Quoted delimiter only: bash expands $(…) and backticks inside an unquoted
  # heredoc body, so that body is code and stays scanned.
  local re_start="<<-?[[:space:]]*('([A-Za-z_][A-Za-z0-9_]*)'|\"([A-Za-z_][A-Za-z0-9_]*)\")"
  local re_sink='^[[:space:]]*(cat|tee|git[[:space:]]+commit)([[:space:]]|$)'
  # chains, pipes, substitutions, process substitution >(…), and a trailing
  # backslash that continues the line (`cat <<'EOF' \` + `| bash`)
  local re_chain='[;|&`()]|\\[[:space:]]*$'
  local line trimmed delim="" closed=0 out=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    if (( closed )); then
      # more commands after the heredoc: it does not close the command
      if [[ -n "${line//[[:space:]]/}" ]]; then printf '%s' "$1"; return; fi
      continue
    fi
    if [[ -n "$delim" ]]; then
      trimmed="${line#"${line%%[!$'\t']*}"}"   # <<- allows leading tabs
      if [[ "$trimmed" == "$delim" ]]; then closed=1; fi
      continue
    fi
    out+="$line"$'\n'
    if [[ "$line" =~ $re_start ]]; then
      local d="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
      if [[ "$line" =~ $re_sink ]] && ! [[ "$line" =~ $re_chain ]]; then
        delim="$d"
      else
        printf '%s' "$1"; return
      fi
    fi
  done <<< "$1"
  printf '%s' "$out"
}

command=$(strip_data_heredoc "$command")

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

ask() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

has() { printf '%s' "$command" | grep -Eq "$1"; }

if has '(^|[^[:alnum:]_])sudo([^[:alnum:]_]|$)'; then
  deny "Blocked by bash-guard.sh: \`sudo\` is not permitted."
fi

if has '(^|[^[:alnum:]_])db:wipe([^[:alnum:]_]|$)'; then
  deny "Blocked by bash-guard.sh: \`db:wipe\` drops a database."
fi

# git push in any spelling: `git push`, `git -C dir push`, `git -c k=v push`
push='(^|[^[:alnum:]_])git([[:space:]]+-[Cc][[:space:]]*[^[:space:]]+)*[[:space:]]+push([^[:alnum:]_-]|$)'
if has "$push"; then
  if has '(^|[[:space:]])(--force|-f|--force-with-lease[^[:space:]]*)([[:space:]]|$)' || has '[[:space:]]\+[^[:space:]]+([[:space:]]|$)'; then
    deny "Blocked by bash-guard.sh: force push rewrites remote history."
  fi
  ask "bash-guard.sh: \`git push\` — the acceptance gate, confirm."
fi

if has '(^|[^[:alnum:]_])migrate:fresh([^[:alnum:]_]|$)'; then
  ask "bash-guard.sh: \`migrate:fresh\` drops and rebuilds a database — confirm it targets this worktree's test DB."
fi

if has '(^|[^[:alnum:]_])compose([^[:alnum:]_]|$)' && has '(^|[^[:alnum:]_])down([^[:alnum:]_]|$)' && has '(^|[[:space:]])(-v|--volumes)([[:space:]]|$)'; then
  ask "bash-guard.sh: \`docker compose down\` with volumes deletes the stack's data — confirm."
fi

exit 0   # no objection — normal allow/ask/deny rules then apply
