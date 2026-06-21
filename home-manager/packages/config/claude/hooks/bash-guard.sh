#!/usr/bin/env bash
# PreToolUse guard for Bash.
#
# Catches `sudo` / `rm` ANYWHERE in the command string (not just at the start of
# a parsed sub-command, which is all the settings.json permission patterns can
# see). Version-controlled in the dotfiles repo and symlinked to
# ~/.claude/hooks/bash-guard.sh via mkOutOfStoreSymlink (see
# home-manager/packages/commons.nix).
#
#   sudo  -> deny  (hard block)
#   rm    -> ask   (prompt; covers $(rm ...), `xargs rm`, etc.)
#
# The (^|[^[:alnum:]_])WORD([^[:alnum:]_]|$) boundary matches the word in any
# position (after a space, '(', '&', ';', '|', or string start/end) while not
# matching e.g. `pseudonym` or `rmdir`. Character classes (not \b) keep this
# portable across GNU and BSD grep. Best-effort only: literal-token obfuscation
# (variable indirection, base64, unicode) can still slip past.
set -euo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

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

if printf '%s' "$command" | grep -Eq '(^|[^[:alnum:]_])sudo([^[:alnum:]_]|$)'; then
  deny "Blocked by bash-guard.sh: \`sudo\` is not permitted."
fi

if printf '%s' "$command" | grep -Eq '(^|[^[:alnum:]_])rm([^[:alnum:]_]|$)'; then
  ask "bash-guard.sh: \`rm\` detected — confirm before running."
fi

exit 0   # no objection — normal allow/ask/deny rules then apply
