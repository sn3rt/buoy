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
ratio = [1, 4, 0]

[preview]
max_width = 1
max_height = 1
image_delay = 1000000

[plugin]
prepend_previewers = [
  { mime = "image/*", run = "noop" },
  { mime = "video/*", run = "noop" },
  { mime = "application/pdf", run = "noop" },
]
prepend_preloaders = [
  { mime = "image/*", run = "noop" },
  { mime = "video/*", run = "noop" },
  { mime = "application/pdf", run = "noop" },
]
EOF

YAZI_CONFIG_HOME="$config_dir" exec yazi "$session_path"
