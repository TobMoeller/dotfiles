#!/usr/bin/env bash
# statusLine hook: permanent usage / quota display.
#
# Replaces having to type /usage. Claude Code pipes a JSON status blob into this
# script on stdin after every turn and renders the single line we print on stdout,
# just below the prompt box. Renders:
#
#   opus-5  main*  5h 24% · 7d 41% · ctx 38% · $1.23
#
# The rate-limit numbers are the *consumed* share of the rolling 5-hour and 7-day
# subscription windows (so 24% means 76% left). They are colour-coded green /
# yellow / red, and once a window passes 80% the reset clock time is appended:
#   5h 84%→14:30
#
# CAVEAT: .rate_limits is only sent on Claude.ai subscription auth (Pro/Max) and
# only *after the first API response* of a session — a fresh session legitimately
# shows no percentages for one turn. Every field is therefore optional and simply
# omitted when absent, never rendered as 0 or "null".
#
# Version-controlled in the dotfiles repo and symlinked to
# ~/.claude/statusline.sh via mkOutOfStoreSymlink (see
# home-manager/packages/commons.nix), so edits take effect immediately — no
# home-manager switch needed. Wired up via "statusLine" in
# packages/config/claude/settings.json (that one IS generated, so changing the
# wiring does need a switch).
#
# Debugging: export CLAUDE_STATUSLINE_DEBUG=/tmp/statusline.json to dump the raw
# stdin blob on each invocation and see exactly which fields the current Claude
# Code version sends.
set -uo pipefail

# jq emits the cost as a dot-decimal number, but printf parses floats according
# to the locale — under de_DE "12.5" silently becomes 12,00. Force the C locale
# for numeric formatting.
export LC_NUMERIC=C

input=$(cat)

[ -n "${CLAUDE_STATUSLINE_DEBUG:-}" ] && printf '%s\n' "$input" >"$CLAUDE_STATUSLINE_DEBUG"

# One jq pass for everything, one field per line. NOT tab-separated + read:
# tab is an IFS *whitespace* character, so consecutive empty fields would
# collapse into one delimiter and shift every later value into the wrong
# variable. mapfile preserves empty lines, so absent fields stay positional.
# Percentages are pre-rounded here to keep the shell free of float arithmetic.
mapfile -t f < <(
  printf '%s' "$input" | jq -r '
    def pct: if . == null then "" else (. | round | tostring) end;
    [ .model.display_name // ""
    , .workspace.current_dir // .cwd // ""
    , (.rate_limits.five_hour.used_percentage | pct)
    , (.rate_limits.five_hour.resets_at // "" | tostring)
    , (.rate_limits.seven_day.used_percentage | pct)
    , (.rate_limits.seven_day.resets_at // "" | tostring)
    , (.context_window.used_percentage | pct)
    , (.cost.total_cost_usd // "" | tostring)
    ] | .[]' 2>/dev/null
)
# Malformed / non-JSON stdin yields no fields — render nothing rather than junk.
[ "${#f[@]}" -eq 8 ] || exit 0

model=${f[0]} cwd=${f[1]}
five_pct=${f[2]} five_reset=${f[3]}
week_pct=${f[4]} week_reset=${f[5]}
ctx_pct=${f[6]} cost=${f[7]}

dim=$'\033[2m'
red=$'\033[31m'
yellow=$'\033[33m'
green=$'\033[32m'
cyan=$'\033[36m'
reset=$'\033[0m'

# Epoch seconds -> local HH:MM. GNU date (Linux) and BSD date (the darwin host)
# disagree on the flag, so try both and tolerate failure.
clock() {
  date -d "@$1" +%H:%M 2>/dev/null || date -r "$1" +%H:%M 2>/dev/null || true
}

# A quota window: green under 50% consumed, yellow under 80%, red above — and
# past 80% append when the window resets, since that is the point where knowing
# "another 90 minutes" changes what you do next.
window() {
  local label=$1 pct=$2 resets=$3 colour
  [ -n "$pct" ] || return 0

  if [ "$pct" -ge 80 ]; then colour=$red
  elif [ "$pct" -ge 50 ]; then colour=$yellow
  else colour=$green
  fi

  local out="${dim}${label}${reset} ${colour}${pct}%${reset}"
  if [ "$pct" -ge 80 ] && [ -n "$resets" ]; then
    local at
    at=$(clock "$resets")
    [ -n "$at" ] && out+="${dim}→${at}${reset}"
  fi
  printf '%s' "$out"
}

parts=()
[ -n "$model" ] && parts+=("${cyan}${model}${reset}")

# Git branch + dirty marker, cheap enough to run every turn. --short keeps this
# to one process; no branch name means detached HEAD or not a repo.
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null || true)
  if [ -n "$branch" ]; then
    git -C "$cwd" diff --quiet --ignore-submodules HEAD 2>/dev/null || branch+="*"
    parts+=("${dim}${branch}${reset}")
  fi
fi

five=$(window 5h "$five_pct" "$five_reset")
week=$(window 7d "$week_pct" "$week_reset")
[ -n "$five" ] && parts+=("$five")
[ -n "$week" ] && parts+=("$week")

# Context window: only interesting as it fills up, so stay dim until 70%.
if [ -n "$ctx_pct" ]; then
  if [ "$ctx_pct" -ge 85 ]; then ctx_colour=$red
  elif [ "$ctx_pct" -ge 70 ]; then ctx_colour=$yellow
  else ctx_colour=$dim
  fi
  parts+=("${dim}ctx${reset} ${ctx_colour}${ctx_pct}%${reset}")
fi

[ -n "$cost" ] && parts+=("$(printf '%s$%.2f%s' "$dim" "$cost" "$reset")")

# Join with a dim middot separator.
out=""
for part in "${parts[@]}"; do
  [ -n "$out" ] && out+="${dim} · ${reset}"
  out+="$part"
done
printf '%s\n' "$out"
