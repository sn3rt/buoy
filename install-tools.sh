#!/usr/bin/env bash
set -euo pipefail

# Downloads and installs pinned tool versions from GitHub releases.
# Versions are defined in versions.toml in the same directory.
#
# Usage:
#   ./install-tools.sh              # install all missing tools
#   ./install-tools.sh --update     # install missing/outdated tools
#   ./install-tools.sh --force      # re-download all tools
#   ./install-tools.sh nvim         # install one tool
#   ./install-tools.sh --force fzf  # re-download one tool
#
# Requires: curl, tar, awk, gzip, bzip2, unzip (unzip only needed for yazi)
# Installs to: ${XDG_BIN_HOME:-~/.local/bin}/

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
TOOL_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/dots-tools"
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

  printf '  downloading %s\n' "$url" >&2
  curl -fsSL -o "$archive" "$url" || return 1

  case "$filename" in
    *.tar.gz|*.tgz) tar -xzf "$archive" -C "$dest" || return 1 ;;
    *.tbz|*.tar.bz2)
      if ! command -v bzip2 >/dev/null 2>&1; then
        printf 'install-tools: bzip2 is required to extract %s\n' "$filename" >&2
        printf 'install-tools: install bzip2 with your system package manager, then rerun this script.\n' >&2
        return 1
      fi
      tar -xjf "$archive" -C "$dest" || return 1 ;;
    *.zip)
      if ! command -v unzip >/dev/null 2>&1; then
        printf 'install-tools: unzip is required to extract %s\n' "$filename" >&2
        printf 'install-tools: install unzip with your system package manager, then rerun this script.\n' >&2
        return 1
      fi
      unzip -q "$archive" -d "$dest" || return 1 ;;
    *)
      printf 'install-tools: unknown archive format: %s\n' "$filename" >&2
      return 1 ;;
  esac

  printf '%s' "$dest"
}

install_bin() {
  local src="$1"
  local name="${2:-$(basename "$src")}"
  local target tmp
  mkdir -p "$INSTALL_DIR"
  target="$INSTALL_DIR/$name"
  tmp="$INSTALL_DIR/.$name.tmp.$$"
  cp "$src" "$tmp"
  chmod +x "$tmp"
  mv -f "$tmp" "$target"
  log "  installed $target"
}

link_bin() {
  local src="$1"
  local name="${2:-$(basename "$src")}"
  mkdir -p "$INSTALL_DIR"
  ln -sfn "$src" "$INSTALL_DIR/$name"
  log "  linked $INSTALL_DIR/$name -> $src"
}

# ---------------------------------------------------------------------------
# Per-tool installers

install_nvim() {
  local version="$1" arch="$2"
  local nvim_arch
  case "$arch" in
    x86_64)  nvim_arch="x86_64" ;;
    aarch64) nvim_arch="arm64" ;;
  esac
  local asset="nvim-linux-${nvim_arch}.tar.gz"
  local url="https://github.com/neovim/neovim/releases/download/v${version}/${asset}"
  local dir
  dir="$(unpack_release nvim "$url")"
  local src="$dir/nvim-linux-${nvim_arch}"
  local dest="$TOOL_ROOT/nvim-${version}-${arch}"
  mkdir -p "$TOOL_ROOT"
  rm -rf "$dest"
  cp -R "$src" "$dest"
  link_bin "$dest/bin/nvim" nvim
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

install_eza() {
  local version="$1" arch="$2"
  local eza_target
  case "$arch" in
    x86_64)  eza_target="x86_64-unknown-linux-musl" ;;
    aarch64) eza_target="aarch64-unknown-linux-gnu_no_libgit" ;;
  esac
  local asset="eza_${eza_target}.tar.gz"
  local url="https://github.com/eza-community/eza/releases/download/v${version}/${asset}"
  local dir bin
  dir="$(unpack_release eza "$url")"
  bin="$(find "$dir" -type f -name eza | head -n 1)"
  if [[ -z "$bin" ]]; then
    printf 'install-tools: eza binary not found in %s\n' "$asset" >&2
    return 1
  fi
  install_bin "$bin" eza
}

install_yazi() {
  local version="$1" arch="$2"
  local asset="yazi-${arch}-unknown-linux-musl.zip"
  local url="https://github.com/sxyazi/yazi/releases/download/v${version}/${asset}"
  local dir
  dir="$(unpack_release yazi "$url")" || return 1
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
  local btop_target
  case "$arch" in
    x86_64)  btop_target="x86_64-unknown-linux-musl" ;;
    aarch64) btop_target="aarch64-unknown-linux-musl" ;;
  esac
  local asset="btop-${btop_target}.tar.gz"
  local url="https://github.com/aristocratos/btop/releases/download/v${version}/${asset}"
  local dir bin
  dir="$(unpack_release btop "$url")"
  bin="$(find "$dir" -type f -path '*/bin/btop' -o -type f -name btop | head -n 1)"
  if [[ -z "$bin" ]]; then
    printf 'install-tools: btop binary not found in %s\n' "$asset" >&2
    return 1
  fi
  install_bin "$bin" btop
}

check_tmux_build_deps() {
  local -a missing=()

  if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1; then
    missing+=("C compiler")
  fi

  if ! command -v make >/dev/null 2>&1; then
    missing+=("make")
  fi

  if ! command -v pkg-config >/dev/null 2>&1; then
    missing+=("pkg-config")
  else
    if ! pkg-config --exists libevent; then
      missing+=("libevent")
    fi
    if ! pkg-config --exists ncursesw && ! pkg-config --exists ncurses; then
      missing+=("ncurses")
    fi
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    printf 'install-tools: tmux build dependencies missing: %s\n' "${missing[*]}" >&2
    printf 'install-tools: on Ubuntu/Debian install them with:\n' >&2
    printf '  sudo apt install build-essential pkg-config libevent-dev libncurses-dev\n' >&2
    return 1
  fi
}

install_tmux() {
  local version="$1" arch="$2"
  local asset="tmux-${version}.tar.gz"
  local url="https://github.com/tmux/tmux/releases/download/${version}/${asset}"
  local dir src dest jobs

  check_tmux_build_deps
  dir="$(unpack_release tmux "$url")"
  src="$dir/tmux-${version}"
  dest="$TOOL_ROOT/tmux-${version}-${arch}"

  if [[ ! -x "$src/configure" ]]; then
    printf 'install-tools: tmux configure script not found: %s\n' "$src/configure" >&2
    return 1
  fi

  if command -v nproc >/dev/null 2>&1; then
    jobs="$(nproc)"
  else
    jobs=1
  fi

  mkdir -p "$TOOL_ROOT"
  rm -rf "$dest"
  (
    cd "$src"
    ./configure --prefix="$dest"
    make -j "$jobs"
    make install
  )
  link_bin "$dest/bin/tmux" tmux
}

install_tree_sitter() {
  local version="$1" arch="$2"
  local tree_sitter_arch
  case "$arch" in
    x86_64)  tree_sitter_arch="x64" ;;
    aarch64) tree_sitter_arch="arm64" ;;
  esac
  local asset="tree-sitter-linux-${tree_sitter_arch}.gz"
  local url="https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/${asset}"
  local archive="$WORK_DIR/$asset"
  local bin="$WORK_DIR/tree-sitter"
  printf '  downloading %s\n' "$url" >&2
  curl -fsSL -o "$archive" "$url"
  gzip -dc "$archive" >"$bin"
  install_bin "$bin" tree-sitter
}

dispatch_install() {
  local tool="$1" version="$2" arch="$3"
  case "$tool" in
    nvim)     install_nvim     "$version" "$arch" ;;
    starship) install_starship "$version" "$arch" ;;
    fzf)      install_fzf      "$version" "$arch" ;;
    fd)       install_fd       "$version" "$arch" ;;
    eza)      install_eza      "$version" "$arch" ;;
    yazi)     install_yazi     "$version" "$arch" ;;
    atuin)    install_atuin    "$version" "$arch" ;;
    btop)     install_btop     "$version" "$arch" ;;
    tmux)     install_tmux     "$version" "$arch" ;;
    tree_sitter) install_tree_sitter "$version" "$arch" ;;
    *)
      printf 'install-tools: unknown tool: %s\n' "$tool" >&2
      return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Version + skip logic

tool_bin_name() {
  local tool="$1"
  case "$tool" in
    tree_sitter) printf 'tree-sitter' ;;
    *) printf '%s' "$tool" ;;
  esac
}

installed_version() {
  local tool="$1" bin output
  bin="$(tool_bin_name "$tool")"

  if [[ -x "$INSTALL_DIR/$bin" ]]; then
    bin="$INSTALL_DIR/$bin"
  elif command -v "$bin" >/dev/null 2>&1; then
    bin="$(command -v "$bin")"
  else
    return 1
  fi

  case "$tool" in
    nvim)
      output="$("$bin" -v 2>/dev/null | head -n 1)"
      output="${output#NVIM v}"
      printf '%s\n' "${output%% *}"
      ;;
    starship|fd|atuin|tree_sitter)
      "$bin" --version 2>/dev/null | awk 'NR==1 { print $2 }'
      ;;
    fzf)
      "$bin" --version 2>/dev/null | awk 'NR==1 { print $1 }'
      ;;
    eza)
      "$bin" -v 2>/dev/null | awk '/^v[0-9]/ { sub(/^v/, "", $1); print $1; exit }'
      ;;
    yazi)
      "$bin" --version 2>/dev/null | awk 'NR==1 { print $2 }'
      ;;
    btop)
      "$bin" --version 2>/dev/null | awk '
        NR == 1 {
          gsub(/\033\[[0-9;]*m/, "")
          sub(/^btop version: /, "")
          sub(/\+.*/, "")
          print
        }
      '
      ;;
    tmux)
      "$bin" -V 2>/dev/null | awk 'NR==1 { print $2 }'
      ;;
    *)
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Main

main() {
  local force=0
  local only_tool=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --update|-u) shift ;;
      --force|-f) force=1; shift ;;
      -*)
        printf 'usage: install-tools.sh [--update|-u] [--force|-f] [tool]\n' >&2
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

  local -a TOOLS=(nvim starship fzf fd eza yazi atuin btop tmux tree_sitter)

  for tool in "${TOOLS[@]}"; do
    [[ -n "$only_tool" && "$tool" != "$only_tool" ]] && continue

    local version="${VERSIONS[$tool]-}"
    local current=""
    if [[ -z "$version" ]]; then
      log "[skip] $tool (not in versions.toml)"
      continue
    fi

    current="$(installed_version "$tool" 2>/dev/null || true)"
    if [[ $force -eq 0 && "$current" == "$version" ]]; then
      log "[skip] $tool $version (already installed)"
      continue
    fi

    if [[ -n "$current" ]]; then
      log "[install] $tool $version (installed: $current)"
    else
      log "[install] $tool $version"
    fi
    dispatch_install "$tool" "$version" "$arch"
  done

  log "Done."
}

main "$@"
