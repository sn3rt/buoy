#!/usr/bin/env bash
set -euo pipefail

kind="${1:?missing popup kind}"
pane_id="${2:?missing pane id}"
outer_session_id="${3:?missing outer session id}"
session_path="${4:-$PWD}"
target_client="${5:-}"

shell_quote() {
  printf '%q' "$1"
}

popup_command() {
  local quoted=()
  local arg
  for arg in "$@"; do
    quoted+=("$(shell_quote "$arg")")
  done
  local IFS=' '
  printf '%s' "${quoted[*]}"
}

open_local_popup() {
  local popup_args=(-E -w 90% -h 90% -d "$session_path")
  if [[ -n "$target_client" ]]; then
    popup_args=(-t "$target_client" "${popup_args[@]}")
  fi

  case "$kind" in
    opencode)
      local cmd
      cmd="$(popup_command bash "$HOME/.config/tmux/popup-server.sh" opencode "$HOME/.config/tmux/opencode.conf" opencode "$outer_session_id" "$session_path" opencode)"
      exec tmux display-popup -T "OpenCode" "${popup_args[@]}" \
        "$cmd"
      ;;
    yazi)
      local cmd
      cmd="$(popup_command bash "$HOME/.config/tmux/popup-server.sh" yazi "$HOME/.config/tmux/yazi.conf" yazi "$outer_session_id" "$session_path" yazi)"
      exec tmux display-popup -T "Yazi" "${popup_args[@]}" \
        "$cmd"
      ;;
    fzf)
      local cmd
      tmux set -t "$pane_id" @fzf_popup_target "$pane_id"
      cmd="$(popup_command bash "$HOME/.config/tmux/fzf-popup.sh" "$pane_id")"
      exec tmux display-popup -T "FZF" "${popup_args[@]}" \
        "$cmd"
      ;;
    *)
      printf 'popup-dispatch: unknown kind: %s\n' "$kind" >&2
      exit 2
      ;;
  esac
}

open_local_popup
