#!/usr/bin/env bash
# Herdr injects the calling pane and binary path for plugin actions.
set -euo pipefail

direction="${1:?usage: navigate.sh <left|down|up|right>}"
herdr="${HERDR_BIN_PATH:-herdr}"
pane="${HERDR_PANE_ID:?This action must run inside Herdr}"

case "$direction" in
  left)  key="ctrl+h" ;;
  down)  key="ctrl+j" ;;
  up)    key="ctrl+k" ;;
  right) key="ctrl+l" ;;
  *) echo "Unknown direction: $direction" >&2; exit 2 ;;
esac

# Check all foreground processes, including Vim variants and fzf.
if "$herdr" pane process-info --pane "$pane" |
  jq -e 'any(.result.process_info.foreground_processes[]?;
    .name | ascii_downcase | test("^(g?(view|l?n?vim?x?)(diff)?|fzf)$"))' >/dev/null; then
  exec "$herdr" pane send-keys "$pane" "$key"
fi

exec "$herdr" pane focus --direction "$direction" --pane "$pane"
