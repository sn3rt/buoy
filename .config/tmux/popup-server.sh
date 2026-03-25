#!/usr/bin/env bash
set -euo pipefail

# Start (or attach to) a dedicated tmux server per *outer* tmux session.
#
# Usage:
#   popup-server.sh <name> <conf> <session_name> <cwd> <command...>
#
# We intentionally derive a unique suffix from the outer tmux session id.
# tmux formats return session_id like "$1"; strip the leading '$' so the
# shell doesn't treat it as a positional parameter.

name="${1:?missing name}"
conf="${2:?missing conf path}"
inner_session="${3:?missing inner session name}"
cwd="${4:-$PWD}"
shift 4

wait_for_close() {
  printf '\nPress any key to close...'
  IFS= read -r -n 1 -s _ || true
}

if [[ $# -gt 0 ]]; then
  cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'popup-server: command not found: %s\n' "$cmd" >&2
    printf 'cwd: %s\n' "$cwd" >&2
    wait_for_close
    exit 127
  fi
fi

outer_sid="$(tmux display-message -p '#{session_id}')"
outer_sid="${outer_sid#\$}"

socket_name="${name}-${outer_sid}"

if [[ $# -eq 0 ]]; then
  tmux -L "$socket_name" -f "$conf" new-session -A -s "$inner_session" -c "$cwd"
else
  tmux -L "$socket_name" -f "$conf" new-session -A -s "$inner_session" -c "$cwd" -- "$@"
fi
