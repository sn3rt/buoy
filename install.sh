#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

check_for_updates() {
  command -v git >/dev/null 2>&1 || return 0
  git -C "$REPO_ROOT" fetch --quiet 2>/dev/null || return 0
  git -C "$REPO_ROOT" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1 || return 0
  local behind
  behind="$(git -C "$REPO_ROOT" rev-list --count HEAD..@{u} 2>/dev/null || true)"
  if [[ -n "$behind" && "$behind" -gt 0 ]]; then
    printf 'Note: %s commit(s) available upstream. Run: git -C %s pull\n' \
      "$behind" "$REPO_ROOT" >&2
  fi
}

check_for_updates

abspath() {
  # readlink -f is available on Linux
  readlink -f "$1"
}

backup_target() {
  local target="$1"
  local rel
  rel="${target#"$HOME"/}"
  local dest="$BACKUP_ROOT/$rel"
  mkdir -p "$(dirname "$dest")"
  mv "$target" "$dest"
}

link_item() {
  local src_rel="$1"
  local target="$2"

  local src="$REPO_ROOT/$src_rel"
  if [[ ! -e "$src" ]]; then
    printf 'Missing source: %s\n' "$src" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" ]]; then
    local cur
    cur="$(abspath "$target")"
    if [[ "$cur" == "$(abspath "$src")" ]]; then
      return 0
    fi
    backup_target "$target"
  elif [[ -e "$target" ]]; then
    backup_target "$target"
  fi

  ln -s "$src" "$target"
}

# Shell + scripts
link_item ".zshrc" "$HOME/.zshrc"
link_item ".scripts" "$HOME/.scripts"

# Local commands
link_item ".local/bin/tmx" "$HOME/.local/bin/tmx"
link_item ".local/bin/ssht" "$HOME/.local/bin/ssht"

# Terminal tool configs
link_item ".config/starship.toml" "$HOME/.config/starship.toml"
link_item ".config/atuin" "$HOME/.config/atuin"
link_item ".config/btop" "$HOME/.config/btop"
link_item ".config/kitty" "$HOME/.config/kitty"
link_item ".config/nvim" "$HOME/.config/nvim"
link_item ".config/tmux" "$HOME/.config/tmux"
link_item ".config/yazi" "$HOME/.config/yazi"
link_item ".config/snert-logo" "$HOME/.config/snert-logo"

# tmux reads ~/.tmux.conf on older versions
link_item ".tmux.conf" "$HOME/.tmux.conf"

# OpenCode: link config + plugin manifests, keep node_modules local
mkdir -p "$HOME/.config/opencode"
link_item ".config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
link_item ".config/opencode/package.json" "$HOME/.config/opencode/package.json"
link_item ".config/opencode/bun.lock" "$HOME/.config/opencode/bun.lock"

# Secrets live outside git
mkdir -p "$HOME/.config/secrets"
if [[ ! -f "$HOME/.config/secrets/.zshenv" ]]; then
  printf 'Note: create %s (see %s)\n' \
    "$HOME/.config/secrets/.zshenv" \
    "$REPO_ROOT/.config/secrets/.zshenv.example" >&2
fi

printf 'Done. Backups (if any): %s\n' "$BACKUP_ROOT"
