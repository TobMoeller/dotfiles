#!/usr/bin/env bash
# PermissionRequest hook for Bash: routine project checks inside a ticket
# worktree never need a prompt.
#
# Fires only when Claude Code is about to show a permission prompt (so in auto
# mode it is mostly idle — the classifier decides there; it matters in the
# default/acceptEdits modes and after auto mode falls back to prompting).
# If the cwd is under $WT_ROOT and every `&&`-joined segment of the command is
# one of the read-only or check commands below, the request is answered with
# allow. Anything else stays a prompt for the human.
#
# Deliberately narrow: no redirects, no pipes, no subshells, no `;`, no lone
# `&`, no full test suite, no push. The only migrate is the test-DB bootstrap
# `php artisan migrate --seed --env=testing` (exact), the only compose start is
# `docker compose up -d [service …]` against the worktree's own stack.
# Extend the list here, not with Bash(*).
#
# Version-controlled in the dotfiles repo and symlinked to
# ~/.claude/hooks/worktree-allow.sh via mkOutOfStoreSymlink (see
# home-manager/packages/commons.nix).
set -euo pipefail

CODE_DIR="${WT_CODE_DIR:-$HOME/code}"
WT_ROOT="${WT_ROOT:-$CODE_DIR/worktrees}"

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')

case "$cwd" in
  "$WT_ROOT"/*) ;;
  *) exit 0 ;;
esac

# Shell features that can smuggle anything past a prefix check.
if printf '%s' "$command" | grep -Eq '[;|<>`]|\$\(|\|\|'; then
  exit 0
fi

safe='^((\./)?vendor/bin/phpunit( [^ ]+)*|(\./)?vendor/bin/pint( --test)?( [^ ]+)*|(\./)?vendor/bin/phpstan analyse( [^ ]+)*|php artisan test( [^ ]+)*|php artisan route:list( [^ ]+)*|php artisan migrate:status|composer dump-autoload( -o)?|composer validate|npm run (lint|type-check)( [^ ]+)*|git (status|diff|log|show|branch|rev-parse|merge-base|ls-files|stash list)( [^ ]+)*|git add( [^ ]+)+|docker compose (ps|logs)( [^ ]+)*|docker compose up -d( [a-z0-9][a-z0-9_-]*)*|php artisan migrate --seed --env=testing)$'

# Every segment must match; a leading `cd <this worktree> &&` is tolerated.
ok=1
while IFS= read -r seg; do
  seg="${seg#"${seg%%[![:space:]]*}"}"
  seg="${seg%"${seg##*[![:space:]]}"}"
  [[ -z "$seg" ]] && continue
  # a lone `&` (background job) left after the ` && ` split would let a second
  # command ride on a `( [^ ]+)*` argument list
  [[ "$seg" == *'&'* ]] && { ok=0; break; }
  if [[ "$seg" =~ ^cd[[:space:]]+([^[:space:]]+)$ ]]; then
    target=${BASH_REMATCH[1]}
    target=${target/#\~/$HOME}
    case "$target" in "$WT_ROOT"/*) continue ;; *) ok=0; break ;; esac
  fi
  printf '%s' "$seg" | grep -Eq "$safe" || { ok=0; break; }
done < <(printf '%s\n' "$command" | sed 's/ && /\n/g')   # trailing \n: read must see the last segment too

(( ok )) || exit 0

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PermissionRequest",
    decision: {
      behavior: "allow",
      message: "worktree-allow.sh: routine check inside a ticket worktree"
    }
  }
}'
exit 0
