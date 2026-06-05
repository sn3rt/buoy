#!/usr/bin/env bash
set -euo pipefail

kind="${1:?missing popup kind}"
pane_id="${2:?missing pane id}"
outer_session_id="${3:?missing outer session id}"
outer_session_name="${4:-}"
outer_socket_path="${5:-}"
session_path="${6:-$PWD}"
target_client="${7:-}"
tmux_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
agent_conf="$tmux_config_dir/agent-popup.conf"

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

  tmux display-popup -T "$title" "${popup_args[@]}" "$cmd" || true
}

open_popup() {
  popup_args=(-E -w 90% -h 90% -d "$session_path")

  case "$kind" in
    opencode)
      local cmd
      cmd="$(popup_command bash "$tmux_config_dir/popup-server.sh" opencode "$agent_conf" opencode "$outer_session_id" "$outer_session_name" "$outer_socket_path" "$session_path" opencode)"
      open_tmux_command "OpenCode" "$cmd"
      ;;
    codex)
      local cmd
      cmd="$(popup_command bash "$tmux_config_dir/popup-server.sh" codex "$agent_conf" codex "$outer_session_id" "$outer_session_name" "$outer_socket_path" "$session_path" codex)"
      open_tmux_command "Codex" "$cmd"
      ;;
    claude)
      local cmd
      cmd="$(popup_command bash "$tmux_config_dir/popup-server.sh" claude "$agent_conf" claude "$outer_session_id" "$outer_session_name" "$outer_socket_path" "$session_path" claude)"
      open_tmux_command "Claude" "$cmd"
      ;;
    yazi)
      local cmd
      cmd="$(popup_command bash "$tmux_config_dir/yazi-popup.sh" "$session_path")"
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

open_popup
