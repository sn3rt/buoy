#!/usr/bin/env bash
set -euo pipefail

# Downloads and installs pinned tool versions from GitHub releases.
# Versions are defined in versions.toml in the same directory.
#
# Usage:
#   ./install-tools.sh              # install pinned terminal tools
#   ./install-tools.sh --terminal   # install pinned terminal tools
#   ./install-tools.sh --desktop    # install Arch desktop packages and terminal tools
#   ./install-tools.sh --force      # re-download all terminal tools
#   ./install-tools.sh nvim         # install one terminal tool
#   ./install-tools.sh skillshare   # install the Skillshare CLI
#   ./install-tools.sh hexe         # install Hexe locally (not part of terminal/Nomad defaults)
#
# Checks host dependencies before downloading or installing any pinned tools.
# Installs to: ${XDG_BIN_HOME:-~/.local/bin}/

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
TOOL_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/dots-tools"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

log() {
  printf '%s\n' "$*"
}

usage() {
  printf '%s\n' \
    'usage: install-tools.sh [-t|--terminal|terminal] [--update|-u] [--force|-f] [tool]' \
    '       install-tools.sh [-d|--desktop|desktop] [--update|-u] [--force|-f]' >&2
}

# ---------------------------------------------------------------------------
# Host dependencies

append_unique() {
  local array_name="$1"
  local value="$2"
  local existing
  local -n values="$array_name"

  for existing in "${values[@]}"; do
    [[ "$existing" == "$value" ]] && return 0
  done
  values+=("$value")
}

add_missing_dependency() {
  local label="$1"
  local arch_package="$2"
  local debian_package="$3"

  append_unique missing_dependencies "$label"
  case "$package_manager" in
    pacman) append_unique missing_packages "$arch_package" ;;
    apt)    append_unique missing_packages "$debian_package" ;;
  esac
}

check_command_dependency() {
  local label="$1"
  local command_name="$2"
  local arch_package="$3"
  local debian_package="$4"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    add_missing_dependency "$label" "$arch_package" "$debian_package"
  fi
}

check_tmux_build_dependencies() {
  if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1; then
    add_missing_dependency "C compiler" base-devel build-essential
  fi
  check_command_dependency make make base-devel build-essential
  check_command_dependency yacc yacc base-devel bison

  if ! command -v pkg-config >/dev/null 2>&1; then
    add_missing_dependency pkg-config pkgconf pkg-config
    add_missing_dependency libevent libevent libevent-dev
    add_missing_dependency ncurses ncurses libncurses-dev
    return
  fi

  if ! pkg-config --exists libevent; then
    add_missing_dependency libevent libevent libevent-dev
  fi
  if ! pkg-config --exists ncursesw && ! pkg-config --exists ncurses; then
    add_missing_dependency ncurses ncurses libncurses-dev
  fi
}

check_host_dependencies() {
  local profile="$1"
  local only_tool="$2"
  local package_manager=""
  local -a missing_dependencies=()
  local -a missing_packages=()

  if command -v pacman >/dev/null 2>&1; then
    package_manager="pacman"
  elif command -v apt-get >/dev/null 2>&1; then
    package_manager="apt"
  fi

  # Needed by the installer itself and by the release archive formats.
  check_command_dependency curl curl curl curl
  check_command_dependency awk awk gawk gawk
  check_command_dependency tar tar tar tar
  check_command_dependency gzip gzip gzip gzip
  check_command_dependency bzip2 bzip2 bzip2 bzip2
  check_command_dependency unzip unzip unzip unzip

  # A complete profile should be usable immediately after installation.
  if [[ -z "$only_tool" ]]; then
    check_command_dependency zsh zsh zsh zsh
    check_command_dependency chsh chsh util-linux passwd
    check_command_dependency git git git git
    check_command_dependency ssh ssh openssh openssh-client
    check_command_dependency rg rg ripgrep ripgrep
    check_tmux_build_dependencies
  elif [[ "$only_tool" == "tmux" ]]; then
    check_tmux_build_dependencies
  fi

  if [[ "$profile" == "desktop" || "$only_tool" == "hexe" ]]; then
    check_command_dependency sha256sum sha256sum coreutils coreutils
  fi

  if [[ ${#missing_dependencies[@]} -eq 0 ]]; then
    return 0
  fi

  printf 'install-tools: missing required dependencies: %s\n' "${missing_dependencies[*]}" >&2
  if [[ ${#missing_packages[@]} -gt 0 ]]; then
    printf 'install-tools: install them, then run this script again:\n' >&2
    case "$package_manager" in
      pacman)
        printf '  sudo pacman -S --needed %s\n' "${missing_packages[*]}" >&2
        ;;
      apt)
        printf '  sudo apt install %s\n' "${missing_packages[*]}" >&2
        ;;
    esac
  else
    printf 'install-tools: install them with your system package manager, then run this script again.\n' >&2
  fi
  return 1
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

install_tmux() {
  local version="$1" arch="$2"
  local asset="tmux-${version}.tar.gz"
  local url="https://github.com/tmux/tmux/releases/download/${version}/${asset}"
  local dir src dest jobs

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

install_skillshare() {
  local version="$1" arch="$2"
  local skillshare_arch
  case "$arch" in
    x86_64)  skillshare_arch="amd64" ;;
    aarch64) skillshare_arch="arm64" ;;
  esac
  local asset="skillshare_${version}_linux_${skillshare_arch}.tar.gz"
  local url="https://github.com/runkids/skillshare/releases/download/v${version}/${asset}"
  local dir
  dir="$(unpack_release skillshare "$url")"
  install_bin "$dir/skillshare" skillshare
}

install_hexe() {
  local version="$1" arch="$2"
  local asset="hexe-${arch}-linux.tar.gz"
  local base_url="https://github.com/termworks/hexe/releases/download/${version}"
  local archive="$WORK_DIR/$asset"
  local checksum="$WORK_DIR/$asset.sha256"
  local extract_dir="$WORK_DIR/hexe"
  local dest="$TOOL_ROOT/hexe-${version}-${arch}"

  printf '  downloading %s/%s\n' "$base_url" "$asset" >&2
  curl -fsSL -o "$archive" "$base_url/$asset"
  curl -fsSL -o "$checksum" "$base_url/$asset.sha256"

  if ! command -v sha256sum >/dev/null 2>&1; then
    printf 'install-tools: sha256sum is required to verify Hexe releases\n' >&2
    return 1
  fi
  (
    cd "$WORK_DIR"
    sha256sum -c "$asset.sha256"
  )

  mkdir -p "$extract_dir" "$TOOL_ROOT"
  tar -xzf "$archive" -C "$extract_dir"
  if [[ ! -x "$extract_dir/hexe" ]]; then
    printf 'install-tools: Hexe binary not found in %s\n' "$asset" >&2
    return 1
  fi

  rm -rf "$dest"
  mkdir -p "$dest"
  cp "$extract_dir/hexe" "$dest/hexe"
  chmod +x "$dest/hexe"
  link_bin "$dest/hexe" hexe
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
    skillshare) install_skillshare "$version" "$arch" ;;
    hexe)     install_hexe     "$version" "$arch" ;;
    *)
      printf 'install-tools: unknown tool: %s\n' "$tool" >&2
      return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Desktop packages

check_desktop_host() {
  if [[ ! -f /etc/arch-release ]] || ! command -v pacman >/dev/null 2>&1; then
    printf 'install-tools: desktop mode requires Arch Linux with pacman\n' >&2
    return 1
  fi

  if [[ $EUID -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then
    printf 'install-tools: desktop mode requires sudo when not running as root\n' >&2
    return 1
  fi

  if [[ ! -f "$REPO_ROOT/profiles/desktop.packages" ]]; then
    printf 'install-tools: desktop package manifest not found: %s\n' \
      "$REPO_ROOT/profiles/desktop.packages" >&2
    return 1
  fi
}

install_desktop_packages() {
  local -a packages=()
  local package

  while IFS= read -r package; do
    packages+=("$package")
  done < <(awk 'NF && $1 !~ /^#/ { print $1 }' "$REPO_ROOT/profiles/desktop.packages")

  if [[ ${#packages[@]} -eq 0 ]]; then
    printf 'install-tools: desktop package manifest is empty\n' >&2
    return 1
  fi

  log "[desktop] installing Arch packages"
  if [[ $EUID -eq 0 ]]; then
    pacman -S --needed "${packages[@]}"
  else
    sudo pacman -S --needed "${packages[@]}"
  fi
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
    skillshare)
      "$bin" --version 2>/dev/null | awk 'NR == 1 { sub(/^v/, "", $2); print $2 }'
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
    hexe)
      local resolved base
      resolved="$(readlink -f "$bin" 2>/dev/null || true)"
      base="$(basename "$(dirname "$resolved")")"
      if [[ "$base" == hexe-*-* ]]; then
        base="${base#hexe-}"
        printf '%s\n' "${base%-*}"
      else
        return 1
      fi
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
  local profile="terminal"
  local profile_set=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--terminal|terminal)
        if [[ $profile_set -eq 1 && "$profile" != "terminal" ]]; then
          usage
          exit 2
        fi
        profile="terminal"
        profile_set=1
        shift
        ;;
      -d|--desktop|desktop)
        if [[ $profile_set -eq 1 && "$profile" != "desktop" ]]; then
          usage
          exit 2
        fi
        profile="desktop"
        profile_set=1
        shift
        ;;
      --update|-u) shift ;;
      --force|-f) force=1; shift ;;
      --help|-h)
        usage
        exit 0
        ;;
      -*)
        usage
        exit 2
        ;;
      *)
        if [[ -n "$only_tool" ]]; then
          usage
          exit 2
        fi
        only_tool="$1"
        shift
        ;;
    esac
  done

  if [[ "$profile" == "desktop" && -n "$only_tool" ]]; then
    printf 'install-tools: a single tool cannot be selected in desktop mode\n' >&2
    usage
    exit 2
  fi

  case "$only_tool" in
    ""|nvim|starship|fzf|fd|eza|yazi|atuin|btop|tmux|tree_sitter|skillshare|hexe) ;;
    *)
      printf 'install-tools: unknown tool: %s\n' "$only_tool" >&2
      usage
      exit 2
      ;;
  esac

  if [[ "$profile" == "desktop" ]]; then
    check_desktop_host
    install_desktop_packages
  fi

  check_host_dependencies "$profile" "$only_tool"

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

  local -a TOOLS=(nvim starship fzf fd eza yazi atuin btop tmux tree_sitter skillshare)

  # Hexe is a local desktop pilot for now. Keep it out of the default
  # terminal list because Nomad runs that list on remote hosts. An explicit
  # `install-tools.sh hexe` remains available on any supported local Linux.
  if [[ "$profile" == "desktop" || "$only_tool" == "hexe" ]]; then
    TOOLS+=(hexe)
  fi

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

  log "Done ($profile profile)."

  if [[ -z "$only_tool" ]]; then
    local zsh_path login_shell
    zsh_path="$(command -v zsh)"
    login_shell="${SHELL-}"
    if command -v getent >/dev/null 2>&1 && [[ -n "${USER-}" ]]; then
      login_shell="$(getent passwd "$USER" | awk -F: 'NR == 1 { print $7 }')"
    fi

    if [[ "${login_shell##*/}" != "zsh" ]]; then
      printf '\nZsh is installed, but it is not this account '\''s login shell. Run:\n'
      printf '  chsh -s %s\n' "$zsh_path"
      printf 'Then log out and back in. To enter Zsh in this terminal now, run:\n'
      printf '  exec %s -l\n' "$zsh_path"
    fi
  fi
}

main "$@"
