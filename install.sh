#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.buoy-backup/$(date +%Y%m%d-%H%M%S)"

usage() {
  printf 'usage: install.sh [-t|--terminal|terminal] [-d|--desktop|desktop]\n' >&2
}

profile="terminal"
profile_set=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--terminal|terminal)
      if [[ $profile_set -eq 1 && "$profile" != "terminal" ]]; then
        usage
        exit 2
      fi
      profile="terminal"
      profile_set=1
      ;;
    -d|--desktop|desktop)
      if [[ $profile_set -eq 1 && "$profile" != "desktop" ]]; then
        usage
        exit 2
      fi
      profile="desktop"
      profile_set=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
  shift
done

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
  readlink -f "$1" 2>/dev/null || printf '%s\n' "$1"
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

link_manifest() {
  local manifest="$1"
  local item

  if [[ ! -f "$manifest" ]]; then
    printf 'Missing profile manifest: %s\n' "$manifest" >&2
    exit 1
  fi

  # Validate the complete manifest before changing anything in $HOME. This
  # avoids leaving a partially linked profile when an entry is stale or mistyped.
  while IFS= read -r item || [[ -n "$item" ]]; do
    [[ -z "$item" || "$item" == \#* ]] && continue
    if [[ ! -e "$REPO_ROOT/$item" ]]; then
      printf 'Missing source: %s\n' "$REPO_ROOT/$item" >&2
      exit 1
    fi
  done < "$manifest"

  while IFS= read -r item || [[ -n "$item" ]]; do
    [[ -z "$item" || "$item" == \#* ]] && continue
    link_item "$item" "$HOME/$item"
  done < "$manifest"
}

# Remove links created by older versions of the repository.
old_ls_link="$HOME/.local/bin/buoy-ls"
old_ls_repo_link="$REPO_ROOT/.local/bin/buoy-ls"
if [[ -L "$old_ls_link" ]]; then
  old_ls_target="$(abspath "$old_ls_link")"
  old_ls_repo_target="$(abspath "$old_ls_repo_link")"
  if [[ "$old_ls_target" == "$old_ls_repo_target" || ! -e "$old_ls_link" ]]; then
    rm "$old_ls_link"
  fi
fi
legacy_cmd="$(printf 's%s' 'sht')"
legacy_link="$HOME/.local/bin/$legacy_cmd"
legacy_repo_link="$REPO_ROOT/.local/bin/$legacy_cmd"
if [[ -L "$legacy_link" ]]; then
  legacy_target="$(abspath "$legacy_link")"
  legacy_repo_target="$(abspath "$legacy_repo_link")"
  if [[ "$legacy_target" == "$legacy_repo_target" || ! -e "$legacy_link" ]]; then
    rm "$legacy_link"
  fi
fi
old_theme_link="$HOME/.config/buoy-theme"
old_theme_repo_link="$REPO_ROOT/.config/buoy-theme"
if [[ -L "$old_theme_link" ]]; then
  old_theme_target="$(abspath "$old_theme_link")"
  old_theme_repo_target="$(abspath "$old_theme_repo_link")"
  if [[ "$old_theme_target" == "$old_theme_repo_target" || ! -e "$old_theme_link" ]]; then
    rm "$old_theme_link"
  fi
fi

link_manifest "$REPO_ROOT/profiles/terminal.links"
if [[ "$profile" == "desktop" ]]; then
  link_manifest "$REPO_ROOT/profiles/desktop.links"
fi

# Secrets live outside git
mkdir -p "$HOME/.config/secrets"
if [[ ! -f "$HOME/.config/secrets/.zshenv" ]]; then
  printf 'Note: create %s (see %s)\n' \
    "$HOME/.config/secrets/.zshenv" \
    "$REPO_ROOT/.config/secrets/.zshenv.example" >&2
fi

printf 'Done (%s profile). Backups (if any): %s\n' "$profile" "$BACKUP_ROOT"
