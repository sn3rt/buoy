#!/usr/bin/env bash
set -uo pipefail

tmp="$(mktemp "${TMPDIR:-/tmp}/buoy-tmux-copy.XXXXXXXX")"
trap 'rm -f "$tmp"' EXIT

cat > "$tmp"

if [[ ! -s "$tmp" ]]; then
  exit 0
fi

if [[ -n "${BUOY_OUTER_TMUX_SOCKET-}" ]] && command -v tmux >/dev/null 2>&1; then
  if tmux -S "$BUOY_OUTER_TMUX_SOCKET" load-buffer -w - < "$tmp" 2>/dev/null; then
    exit 0
  fi
fi

if [[ -n "${WAYLAND_DISPLAY-}" ]] && command -v wl-copy >/dev/null 2>&1; then
  if wl-copy < "$tmp" 2>/dev/null; then
    exit 0
  fi
fi

if command -v tmux >/dev/null 2>&1; then
  tmux load-buffer -w - < "$tmp" 2>/dev/null || true
fi
