#!/usr/bin/env bash
set -euo pipefail

session_path="${1:-$PWD}"
config_dir="$(mktemp -d "${TMPDIR:-/tmp}/yazi-popup.XXXXXXXX")"
trap 'rm -rf "$config_dir"' EXIT

wait_for_close() {
  printf '\nPress any key to close...'
  IFS= read -r -n 1 -s _ || true
}

if ! command -v yazi >/dev/null 2>&1; then
  printf 'yazi-popup: command not found: yazi\n' >&2
  printf 'cwd: %s\n' "$session_path" >&2
  wait_for_close
  exit 127
fi

cat >"$config_dir/yazi.toml" <<'EOF'
[mgr]
linemode = "btime_and_size"

[preview]
max_width = 1
max_height = 1
image_delay = 100

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
  { mime = "image/*", run = "noop" },
  { mime = "video/*", run = "noop" },
  { mime = "application/pdf", run = "noop" },
  { mime = "image/tiff", run = "noop" },
  { url = "*.tif",  run = "noop" },
  { url = "*.tiff", run = "noop" },
]
prepend_preloaders = [
  { mime = "image/*", run = "noop" },
  { mime = "video/*", run = "noop" },
  { mime = "application/pdf", run = "noop" },
  { mime = "image/tiff", run = "noop" },
  { url = "*.tif",  run = "noop" },
  { url = "*.tiff", run = "noop" },
]
EOF

if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/yazi/init.lua" ]]; then
  ln -s "${XDG_CONFIG_HOME:-$HOME/.config}/yazi/init.lua" "$config_dir/init.lua"
fi

YAZI_CONFIG_HOME="$config_dir" exec yazi "$session_path"
