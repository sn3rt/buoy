#!/usr/bin/env bash
set -euo pipefail

# Checks GitHub latest releases against versions.toml.
#
# Usage:
#   ./update-versions.sh            # check all tools, ask before updating versions.toml
#   ./update-versions.sh eza        # check one tool
#   ./update-versions.sh --write    # update versions.toml to latest releases
#   ./update-versions.sh --write eza

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_FILE="$REPO_ROOT/versions.toml"

TOOLS=(nvim starship fzf fd eza yazi atuin btop tmux tree_sitter)

declare -A REPOS=(
  [nvim]="neovim/neovim"
  [starship]="starship/starship"
  [fzf]="junegunn/fzf"
  [fd]="sharkdp/fd"
  [eza]="eza-community/eza"
  [yazi]="sxyazi/yazi"
  [atuin]="atuinsh/atuin"
  [btop]="aristocratos/btop"
  [tmux]="tmux/tmux"
  [tree_sitter]="tree-sitter/tree-sitter"
)

usage() {
  printf 'usage: update-versions.sh [--write] [tool]\n' >&2
}

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

latest_version() {
  local tool="$1" repo="${REPOS[$tool]}" url tag

  url="$(curl -fsSIL -o /dev/null -w '%{url_effective}' "https://github.com/${repo}/releases/latest")"
  tag="${url##*/}"
  tag="${tag#v}"

  if [[ -z "$tag" || "$tag" == "latest" ]]; then
    printf 'update-versions: could not resolve latest release for %s\n' "$tool" >&2
    return 1
  fi

  printf '%s\n' "$tag"
}

tool_exists() {
  local want="$1" tool
  for tool in "${TOOLS[@]}"; do
    [[ "$tool" == "$want" ]] && return 0
  done
  return 1
}

write_versions() {
  local tmp="$VERSIONS_FILE.tmp.$$"
  local line tool updated=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    updated=0
    for tool in "${selected_tools[@]}"; do
      if [[ "$line" =~ ^${tool}[[:space:]]*= && -n "${LATEST[$tool]-}" ]]; then
        printf '%s = "%s"\n' "$tool" "${LATEST[$tool]}"
        updated=1
        break
      fi
    done
    [[ $updated -eq 0 ]] && printf '%s\n' "$line"
  done < "$VERSIONS_FILE" > "$tmp"

  mv "$tmp" "$VERSIONS_FILE"
}

confirm_write() {
  local answer

  printf 'Update versions.toml to these latest versions? [y/N] '
  if ! IFS= read -r answer; then
    printf '\n'
    return 1
  fi
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

main() {
  local write=0 only_tool="" tool current latest status changed=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --write|-w)
        write=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        usage
        exit 1
        ;;
      *)
        only_tool="$1"
        shift
        if [[ $# -gt 0 ]]; then
          usage
          exit 1
        fi
        ;;
    esac
  done

  if [[ ! -f "$VERSIONS_FILE" ]]; then
    printf 'update-versions: versions.toml not found: %s\n' "$VERSIONS_FILE" >&2
    exit 1
  fi

  if [[ -n "$only_tool" ]] && ! tool_exists "$only_tool"; then
    printf 'update-versions: unknown tool: %s\n' "$only_tool" >&2
    exit 1
  fi

  declare -A CURRENT=()
  while IFS='=' read -r tool current; do
    CURRENT["$tool"]="$current"
  done < <(parse_versions "$VERSIONS_FILE")

  selected_tools=()
  if [[ -n "$only_tool" ]]; then
    selected_tools=("$only_tool")
  else
    selected_tools=("${TOOLS[@]}")
  fi

  declare -gA LATEST=()

  printf '%-14s %-12s %-12s %s\n' tool pinned latest status
  for tool in "${selected_tools[@]}"; do
    current="${CURRENT[$tool]-}"
    if [[ -z "$current" ]]; then
      printf '%-14s %-12s %-12s %s\n' "$tool" "-" "-" "missing from versions.toml"
      continue
    fi

    if ! latest="$(latest_version "$tool")"; then
      printf '%-14s %-12s %-12s %s\n' "$tool" "$current" "-" "check failed"
      continue
    fi

    LATEST["$tool"]="$latest"
    if [[ "$current" == "$latest" ]]; then
      status="current"
    else
      status="update available"
      changed=1
    fi

    printf '%-14s %-12s %-12s %s\n' "$tool" "$current" "$latest" "$status"
  done

  if [[ $write -eq 1 ]]; then
    if [[ $changed -eq 1 ]]; then
      write_versions
      printf 'Updated %s\n' "$VERSIONS_FILE"
    else
      printf 'No version changes.\n'
    fi
  elif [[ -z "$only_tool" && $changed -eq 1 ]]; then
    if confirm_write; then
      write_versions
      printf 'Updated %s\n' "$VERSIONS_FILE"
    else
      printf 'No changes written.\n'
    fi
  fi
}

main "$@"
