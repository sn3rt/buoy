#!/usr/bin/env bash
set -euo pipefail

# Start (or attach to) a dedicated tmux server per *outer* tmux session.
#
# Usage:
#   popup-server.sh <name> <conf> <session_name> <outer_session_id> <outer_session_name> <outer_socket_path> <cwd> <command...>
#
# We intentionally derive a unique suffix from the outer tmux session id,
# captured by the outer tmux server before the popup shell starts.

name="${1:?missing name}"
conf="${2:?missing conf path}"
inner_session="${3:?missing inner session name}"
outer_sid="${4:?missing outer session id}"
outer_session_name="${5:-}"
outer_socket_path="${6:-}"
cwd="${7:-$PWD}"
shift 7

shell_quote() {
  printf '%q' "$1"
}

short_hash() {
  if command -v sha1sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha1sum | awk '{print substr($1, 1, 10)}'
  else
    printf '%s' "$1" | cksum | awk '{print $1}'
  fi
}

safe_name() {
  local value="$1"
  value="${value//[^A-Za-z0-9._-]/-}"
  [[ -n "$value" ]] || value="session"
  printf '%.32s' "$value"
}

resolve_login_shell() {
  local shell_path="${SHELL:-}"

  if [[ -n "$shell_path" && -x "$shell_path" ]]; then
    printf '%s\n' "$shell_path"
    return 0
  fi

  shell_path="$(command -v zsh || command -v sh)"
  printf '%s\n' "$shell_path"
}

build_shell_command() {
  local quoted=()
  local arg

  for arg in "$@"; do
    quoted+=("$(shell_quote "$arg")")
  done

  local IFS=' '
  printf 'exec %s' "${quoted[*]}"
}

resolve_claude_session() {
  local project_key project_dir files=() latest_file

  project_key="${cwd//\//-}"
  project_dir="$HOME/.claude/projects/$project_key"
  [[ -d "$project_dir" ]] || return 0

  shopt -s nullglob
  files=("$project_dir"/*.jsonl)
  shopt -u nullglob
  [[ ${#files[@]} -gt 0 ]] || return 0

  latest_file=""
  local f
  for f in "${files[@]}"; do
    [[ -z "$latest_file" || "$f" -nt "$latest_file" ]] && latest_file="$f"
  done
  [[ -n "$latest_file" ]] || return 0

  basename "$latest_file" .jsonl
}

resolve_login_path() {
  local path_value

  path_value="$("$login_shell" -lc 'printf %s "$PATH"')"
  printf '%s\n' "$path_value"
}

wait_for_close() {
  printf '\nPress any key to close...'
  IFS= read -r -n 1 -s _ || true
}

login_shell="$(resolve_login_shell)"
login_path="$(resolve_login_path)"
PATH="$login_path"

if [[ $# -gt 0 ]]; then
  cmd="$1"
  if ! "$login_shell" -lc "command -v $(shell_quote "$cmd") >/dev/null 2>&1"; then
    printf 'popup-server: command not found: %s\n' "$cmd" >&2
    printf 'cwd: %s\n' "$cwd" >&2
    wait_for_close
    exit 127
  fi
fi

if [[ $# -gt 0 && "$1" == "codex" ]]; then
  set -- bash -lc 'if codex resume --last 2>/dev/null; then exit 0; fi; exec codex'
fi

if [[ $# -gt 0 && "$1" == "claude" ]]; then
  claude_session="$(resolve_claude_session)"
  if [[ -n "$claude_session" ]]; then
    set -- claude --resume "$claude_session"
  else
    set -- claude
  fi
fi

outer_sid="${outer_sid#\$}"
outer_session_name="$(safe_name "$outer_session_name")"

socket_hash="$(short_hash "${outer_socket_path}|${outer_sid}|${outer_session_name}|${cwd}")"
socket_name="${name}-${outer_session_name}-${socket_hash}"

env -u TMUX tmux -L "$socket_name" source-file "$conf" 2>/dev/null || true

if [[ $# -eq 0 ]]; then
  env -u TMUX tmux -L "$socket_name" -f "$conf" new-session -A -s "$inner_session" -c "$cwd" -e "PATH=$login_path" -e "SHELL=$login_shell"
else
  env -u TMUX tmux -L "$socket_name" -f "$conf" new-session -A -s "$inner_session" -c "$cwd" -e "PATH=$login_path" -e "SHELL=$login_shell" -- "$@"
fi
