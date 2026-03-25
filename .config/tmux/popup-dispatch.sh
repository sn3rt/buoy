#!/usr/bin/env bash
set -euo pipefail

kind="${1:?missing popup kind}"
pane_id="${2:?missing pane id}"
session_path="${3:-$PWD}"

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

open_local_popup
