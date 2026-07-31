#!/usr/bin/env bash
#
# vim-nav — herdr side. Invoked by herdr as: navigate.sh <left|down|up|right>.
# herdr injects HERDR_PANE_ID (the focused pane) and HERDR_BIN_PATH.
#
# If the focused pane's foreground process is Vim/Neovim or fzf, forward the
# matching Ctrl chord into that pane (so Vim moves its own splits, fzf/telescope
# moves its list; at a split edge Vim calls back into herdr — see nvim.nix). For
# any other process, move herdr's pane focus. Needs `jq`; without it, every key
# just moves the herdr pane (no vim/fzf awareness).
set -euo pipefail

dir="${1:?usage: navigate.sh <left|down|up|right>}"
herdr="${HERDR_BIN_PATH:-herdr}"
pane="${HERDR_PANE_ID:-}"

case "$dir" in
  left)  key="ctrl+h" ;;
  down)  key="ctrl+j" ;;
  up)    key="ctrl+k" ;;
  right) key="ctrl+l" ;;
  *) echo "navigate.sh: unknown direction: $dir" >&2; exit 2 ;;
esac

# Foreground process names that own Ctrl+hjkl themselves: the vim family (same
# matcher vim-tmux-navigator uses) plus fzf.
match_re='^(g?(view|l?n?vim?x?)(diff)?|fzf)$'

forward=0
if [ -n "$pane" ] && command -v jq >/dev/null 2>&1; then
  if "$herdr" pane process-info --current 2>/dev/null \
    | jq -e --arg re "$match_re" \
        '.result.process_info.foreground_processes[]?.name
         | ascii_downcase | select(test($re))' >/dev/null 2>&1; then
    forward=1
  fi
fi

if [ "$forward" -eq 1 ]; then
  exec "$herdr" pane send-keys "$pane" "$key"
else
  exec "$herdr" pane focus --direction "$dir" --current
fi
