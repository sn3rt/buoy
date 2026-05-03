#!/usr/bin/env bash
set -euo pipefail

# Downloads and installs pinned tool versions from GitHub releases.
# Versions are defined in versions.toml in the same directory.
#
# Usage:
#   ./install-tools.sh              # install all missing tools
#   ./install-tools.sh --update     # re-download all tools
#   ./install-tools.sh nvim         # install one tool
#   ./install-tools.sh --update fzf # re-download one tool
#
# Requires: curl, tar, awk, unzip (unzip only needed for yazi)
# Installs to: ~/.local/bin/

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

log() {
  printf '%s\n' "$*"
}

# ---------------------------------------------------------------------------
# Architecture

detect_arch() {
  case "$(uname -m)" in
    x86_64)  printf 'x86_64' ;;
    aarch64) printf 'aarch64' ;;
    *)
      printf 'install-tools: unsupported architecture: %s\n' "$(uname -m)" >&2
      exit 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# TOML parsing

parse_versions() {
  awk '
    /^\[tools\]/     { in_section=1; next }
    /^\[/            { in_section=0 }
    in_section && /^[a-z_]+ *= *"[^"]+"/ {
      val=$0
      sub(/^[^"]*"/, "", val)
      sub(/".*$/,    "", val)
      print $1 "=" val
    }
  ' "$1"
}

# ---------------------------------------------------------------------------
# Download + extract helpers

unpack_release() {
  local tool="$1"
  local url="$2"
  local dest="$WORK_DIR/$tool"
  mkdir -p "$dest"

  local filename
  filename="$(basename "$url")"
  local archive="$WORK_DIR/$filename"

  log "  downloading $url"
  curl -fsSL -o "$archive" "$url"

  case "$filename" in
    *.tar.gz|*.tgz) tar -xzf "$archive" -C "$dest" ;;
    *.tbz|*.tar.bz2) tar -xjf "$archive" -C "$dest" ;;
    *.zip)           unzip -q "$archive" -d "$dest" ;;
    *)
      printf 'install-tools: unknown archive format: %s\n' "$filename" >&2
      return 1 ;;
  esac

  printf '%s' "$dest"
}

install_bin() {
  local src="$1"
  local name="${2:-$(basename "$src")}"
  mkdir -p "$INSTALL_DIR"
  cp "$src" "$INSTALL_DIR/$name"
  chmod +x "$INSTALL_DIR/$name"
  log "  installed $INSTALL_DIR/$name"
}

# ---------------------------------------------------------------------------
# Per-tool installers

install_nvim() {
  local version="$1" arch="$2"
  local asset="nvim-linux-${arch}.tar.gz"
  local url="https://github.com/neovim/neovim/releases/download/v${version}/${asset}"
  local dir
  dir="$(unpack_release nvim "$url")"
  install_bin "$dir/nvim-linux-${arch}/bin/nvim"
}

install_starship() {
  local version="$1" arch="$2"
  local asset="starship-${arch}-unknown-linux-musl.tar.gz"
  local url="https://github.com/starship/starship/releases/download/v${version}/${asset}"
  local dir
  dir="$(unpack_release starship "$url")"
  install_bin "$dir/starship"
}

install_fzf() {
  local version="$1" arch="$2"
  local fzf_arch
  case "$arch" in
    x86_64)  fzf_arch="amd64" ;;
    aarch64) fzf_arch="arm64" ;;
  esac
  local asset="fzf-${version}-linux_${fzf_arch}.tar.gz"
  local url="https://github.com/junegunn/fzf/releases/download/v${version}/${asset}"
  local dir
  dir="$(unpack_release fzf "$url")"
  install_bin "$dir/fzf"
}

install_fd() {
  local version="$1" arch="$2"
  local asset="fd-v${version}-${arch}-unknown-linux-musl.tar.gz"
  local url="https://github.com/sharkdp/fd/releases/download/v${version}/${asset}"
  local dir
  dir="$(unpack_release fd "$url")"
  install_bin "$dir/fd-v${version}-${arch}-unknown-linux-musl/fd"
}

install_yazi() {
  local version="$1" arch="$2"
  local asset="yazi-${arch}-unknown-linux-musl.zip"
  local url="https://github.com/sxyazi/yazi/releases/download/v${version}/${asset}"
  local dir
  dir="$(unpack_release yazi "$url")"
  local inner="$dir/yazi-${arch}-unknown-linux-musl"
  install_bin "$inner/yazi"
  install_bin "$inner/ya"
}

install_atuin() {
  local version="$1" arch="$2"
  local asset="atuin-${arch}-unknown-linux-musl.tar.gz"
  local url="https://github.com/atuinsh/atuin/releases/download/v${version}/${asset}"
  local dir
  dir="$(unpack_release atuin "$url")"
  install_bin "$dir/atuin-${arch}-unknown-linux-musl/atuin"
}

install_btop() {
  local version="$1" arch="$2"
  local asset="btop-${arch}-linux-musl.tbz"
  local url="https://github.com/aristocratos/btop/releases/download/v${version}/${asset}"
  local dir
  dir="$(unpack_release btop "$url")"
  install_bin "$dir/btop/bin/btop"
}

dispatch_install() {
  local tool="$1" version="$2" arch="$3"
  case "$tool" in
    nvim)     install_nvim     "$version" "$arch" ;;
    starship) install_starship "$version" "$arch" ;;
    fzf)      install_fzf      "$version" "$arch" ;;
    fd)       install_fd       "$version" "$arch" ;;
    yazi)     install_yazi     "$version" "$arch" ;;
    atuin)    install_atuin    "$version" "$arch" ;;
    btop)     install_btop     "$version" "$arch" ;;
    *)
      printf 'install-tools: unknown tool: %s\n' "$tool" >&2
      return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Skip logic

is_installed() {
  local tool="$1"
  [[ -x "$INSTALL_DIR/$tool" ]] || command -v "$tool" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Main

main() {
  local update=0
  local only_tool=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --update|-u) update=1; shift ;;
      -*)
        printf 'usage: install-tools.sh [--update|-u] [tool]\n' >&2
        exit 1 ;;
      *)
        only_tool="$1"; shift ;;
    esac
  done

  local arch
  arch="$(detect_arch)"

  local toml="$REPO_ROOT/versions.toml"
  if [[ ! -f "$toml" ]]; then
    printf 'install-tools: versions.toml not found: %s\n' "$toml" >&2
    exit 1
  fi

  declare -A VERSIONS
  while IFS='=' read -r key val; do
    VERSIONS["$key"]="$val"
  done < <(parse_versions "$toml")

  local -a TOOLS=(nvim starship fzf fd yazi atuin btop)

  for tool in "${TOOLS[@]}"; do
    [[ -n "$only_tool" && "$tool" != "$only_tool" ]] && continue

    local version="${VERSIONS[$tool]-}"
    if [[ -z "$version" ]]; then
      log "[skip] $tool (not in versions.toml)"
      continue
    fi

    if [[ $update -eq 0 ]] && is_installed "$tool"; then
      log "[skip] $tool (already installed; use --update to reinstall)"
      continue
    fi

    log "[install] $tool $version"
    dispatch_install "$tool" "$version" "$arch"
  done

  log "Done."
}

main "$@"
