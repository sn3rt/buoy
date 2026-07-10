#!/usr/bin/env bash
set -uo pipefail

tmp="$(mktemp "${TMPDIR:-/tmp}/buoy-tmux-copy.XXXXXXXX")"
trap 'rm -f "$tmp"' EXIT

cat > "$tmp"

if [[ ! -s "$tmp" ]]; then
  exit 0
fi

copy_to_outer_tmux() {
  [[ -n "${BUOY_OUTER_TMUX_SOCKET-}" ]] || return 1
  command -v tmux >/dev/null 2>&1 || return 1
  tmux -S "$BUOY_OUTER_TMUX_SOCKET" load-buffer -w - < "$tmp" 2>/dev/null
}

copy_to_osc52() {
  local tty="${BUOY_OUTER_CLIENT_TTY-}"
  local encoded

  [[ -n "$tty" && -w "$tty" ]] || return 1

  encoded="$(base64 < "$tmp" | tr -d '\n')"
  [[ -n "$encoded" ]] || return 1

  printf '\033]52;c;%s\a' "$encoded" > "$tty"
}

copy_to_wayland() {
  [[ -n "${WAYLAND_DISPLAY-}" ]] || return 1
  command -v wl-copy >/dev/null 2>&1 || return 1
  wl-copy < "$tmp" 2>/dev/null
}

copy_to_tmux() {
  command -v tmux >/dev/null 2>&1 || return 1
  tmux load-buffer -w - < "$tmp" 2>/dev/null
}

if [[ -n "${BUOY_OUTER_TMUX_SOCKET-}" ]] && command -v tmux >/dev/null 2>&1; then
  copy_to_outer_tmux || true
fi

if [[ -n "${SSH_CONNECTION-}${SSH_CLIENT-}" ]]; then
  if copy_to_osc52; then
    exit 0
  fi
fi

if copy_to_wayland; then
  exit 0
fi

copy_to_tmux || true
