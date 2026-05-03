#!/usr/bin/env bash
set -euo pipefail

kind="${1:?missing popup kind}"
pane_id="${2:?missing pane id}"
outer_session_id="${3:?missing outer session id}"
session_path="${4:-$PWD}"
target_client="${5:-}"
tmux_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"

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

open_tmux_command() {
  local title="$1"
  local cmd="$2"
  local err

  if err="$(tmux display-popup -T "$title" "${popup_args[@]}" "$cmd" 2>&1)"; then
    return 0
  fi

  tmux display-message -d 4000 "${title} popup unavailable; opened in a window instead"
  exec tmux new-window -n "$title" -c "$session_path" "$cmd"
}

open_local_popup() {
  popup_args=(-E -w 90% -h 90% -d "$session_path")

  case "$kind" in
    opencode)
      local cmd
      cmd="$(popup_command bash "$tmux_config_dir/popup-server.sh" opencode "$tmux_config_dir/opencode.conf" opencode "$outer_session_id" "$session_path" opencode)"
      open_tmux_command "OpenCode" "$cmd"
      ;;
    claude)
      local cmd
      cmd="$(popup_command bash "$tmux_config_dir/popup-server.sh" claude "$tmux_config_dir/claude.conf" claude "$outer_session_id" "$session_path" claude)"
      open_tmux_command "Claude" "$cmd"
      ;;
    yazi)
      local cmd
      cmd="$(popup_command bash "$tmux_config_dir/popup-server.sh" yazi "$tmux_config_dir/yazi.conf" yazi "$outer_session_id" "$session_path" yazi)"
      open_tmux_command "Yazi" "$cmd"
      ;;
    fzf)
      local cmd
      tmux set -t "$pane_id" @fzf_popup_target "$pane_id"
      cmd="$(popup_command bash "$tmux_config_dir/fzf-popup.sh" "$pane_id")"
      open_tmux_command "FZF" "$cmd"
      ;;
    *)
      printf 'popup-dispatch: unknown kind: %s\n' "$kind" >&2
      exit 2
      ;;
  esac
}

open_local_popup
