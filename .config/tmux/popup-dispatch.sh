#!/usr/bin/env bash
set -euo pipefail

kind="${1:?missing popup kind}"
pane_id="${2:?missing pane id}"
pane_cmd="${3:-}"
session_path="${4:-$PWD}"

is_remote_pane() {
  case "$pane_cmd" in
    ssh|mosh|mosh-client)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

forward_key() {
  tmux send-keys -t "$pane_id" "$1"
}

open_local_popup() {
  case "$kind" in
    opencode)
      exec tmux display-popup -E -T "OpenCode" -w 90% -h 90% -d "$session_path" \
        "bash \"$HOME/.config/tmux/popup-server.sh\" opencode \"$HOME/.config/tmux/opencode.conf\" opencode \"$session_path\" opencode"
      ;;
    yazi)
      exec tmux display-popup -E -T "Yazi" -w 90% -h 90% -d "$session_path" \
        "bash \"$HOME/.config/tmux/popup-server.sh\" yazi \"$HOME/.config/tmux/yazi.conf\" yazi \"$session_path\" yazi"
      ;;
    fzf)
      tmux set -t "$pane_id" @fzf_popup_target "$pane_id"
      exec tmux display-popup -E -T "FZF" -w 90% -h 90% -d "$session_path" \
        "bash \"$HOME/.config/tmux/fzf-popup.sh\" \"$pane_id\""
      ;;
    *)
      printf 'popup-dispatch: unknown kind: %s\n' "$kind" >&2
      exit 2
      ;;
  esac
}

if is_remote_pane; then
  case "$kind" in
    opencode) exec forward_key M-o ;;
    yazi) exec forward_key M-e ;;
    fzf) exec forward_key M-f ;;
    *)
      printf 'popup-dispatch: unknown kind: %s\n' "$kind" >&2
      exit 2
      ;;
  esac
fi

open_local_popup
