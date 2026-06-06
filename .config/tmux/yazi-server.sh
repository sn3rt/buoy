#!/usr/bin/env bash
set -euo pipefail

action="${1:?missing action}"
outer_sid="${2:-}"
outer_session_name="${3:-}"
outer_socket_path="${4:-}"
cwd="${5:-$PWD}"
tmux_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
conf="$tmux_config_dir/agent-popup.conf"

short_hash() {
  if command -v sha1sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha1sum | awk '{print substr($1, 1, 10)}'
  else
    printf '%s' "$1" | cksum | awk '{print $1}'
  fi
}

numeric_hash() {
  printf '%s' "$1" | cksum | awk '{print $1}'
}

safe_name() {
  local value="$1"
  value="${value//[^A-Za-z0-9._-]/-}"
  [[ -n "$value" ]] || value="session"
  printf '%.32s' "$value"
}

wait_for_close() {
  printf '\nPress any key to close...'
  IFS= read -r -n 1 -s _ || true
}

write_config() {
  mkdir -p "$config_dir"

  cat >"$config_dir/yazi.toml" <<'EOF'
[mgr]
ratio = [1, 4, 0]
linemode = "btime_and_size"

[preview]
max_width = 1
max_height = 1
image_delay = 100

[tasks]
preload_workers = 0

[opener]
imv = [
  { run = "imv %s", orphan = true, desc = "Open in imv", for = "unix" }
]

[open]
prepend_rules = [
  { mime = "image/*", use = "imv" }
]

[plugin]
prepend_previewers = [
  { url = "*", run = "noop" },
  { url = "*/", run = "noop" },
  { mime = "image/*", run = "noop" },
  { mime = "video/*", run = "noop" },
  { mime = "application/pdf", run = "noop" },
  { mime = "image/tiff", run = "noop" },
  { url = "*.tif",  run = "noop" },
  { url = "*.tiff", run = "noop" },
]
prepend_preloaders = [
  { url = "*", run = "noop" },
  { url = "*/", run = "noop" },
  { mime = "image/*", run = "noop" },
  { mime = "video/*", run = "noop" },
  { mime = "application/pdf", run = "noop" },
  { mime = "image/tiff", run = "noop" },
  { url = "*.tif",  run = "noop" },
  { url = "*.tiff", run = "noop" },
]
EOF

  if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/yazi/init.lua" ]]; then
    ln -sf "${XDG_CONFIG_HOME:-$HOME/.config}/yazi/init.lua" "$config_dir/init.lua"
  fi
}

ensure_yazi() {
  if ! command -v yazi >/dev/null 2>&1; then
    printf 'yazi-popup: command not found: yazi\n' >&2
    printf 'cwd: %s\n' "$cwd" >&2
    wait_for_close
    exit 127
  fi

  write_config

  env -u TMUX tmux -L "$socket_name" source-file "$conf" 2>/dev/null || true

  if ! env -u TMUX tmux -L "$socket_name" has-session -t yazi 2>/dev/null; then
    env -u TMUX tmux -L "$socket_name" -f "$conf" new-session -d -s yazi -c "$cwd" \
      -e "YAZI_CONFIG_HOME=$config_dir" -- yazi --client-id "$client_id" "$cwd"
  fi

  ya emit-to "$client_id" cd "$cwd" >/dev/null 2>&1 || true
}

outer_sid="${outer_sid#\$}"
outer_session_name="$(safe_name "$outer_session_name")"

socket_hash="$(short_hash "${outer_socket_path}|${outer_sid}|${outer_session_name}")"
socket_name="yazi-${outer_session_name}-${socket_hash}"
client_id="$(numeric_hash "$socket_name")"
state_root="${TMPDIR:-/tmp}/buoy-yazi-popup"
config_dir="$state_root/$socket_name"

case "$action" in
  warm)
    ensure_yazi >/dev/null 2>&1 || true
    ;;
  open)
    ensure_yazi
    env -u TMUX tmux -L "$socket_name" attach-session -t yazi
    ;;
  *)
    printf 'yazi-server: unknown action: %s\n' "$action" >&2
    exit 2
    ;;
esac
