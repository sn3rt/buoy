#!/usr/bin/env bash
set -euo pipefail

  target_pane="${1:-}"
  if [[ -z "$target_pane" ]]; then
  target_pane="$(tmux show-option -qv @fzf_popup_target || true)"
  fi
if [[ -z "$target_pane" ]]; then
  printf 'fzf-popup: missing target pane id\n' >&2
  exit 2
fi

# If we somehow captured a session id (e.g. $5) instead of a pane id (%5),
# resolve it to the active pane in that session.
if [[ "$target_pane" == \$* ]]; then
  resolved="$(tmux display-message -p -t "$target_pane" '#{pane_id}' 2>/dev/null || true)"
  if [[ -n "$resolved" ]]; then
    target_pane="$resolved"
  fi
fi

editor="${EDITOR:-nvim}"

list_files() {
  if command -v fd >/dev/null 2>&1; then
    fd --hidden --follow --exclude .git --type f .
    return
  fi
  find . -type f -not -path '*/.git/*'
}

file="$(list_files 2>/dev/null | fzf --prompt='files> ' --layout=reverse --exit-0 --bind 'alt-c:abort')"
file="${file#./}"

if [[ -z "$file" ]]; then
  exit 0
fi

sq() {
  # POSIX-ish single-quote escaping: 'foo' -> 'foo', foo'bar -> 'foo'"'"'bar'
  local s="$1"
  printf "'%s'" "${s//\'/\'\"\'\"\'}"
}

if ! tmux list-panes -a -F '#{pane_id}' 2>/dev/null | command grep -Fxq -- "$target_pane"; then
  tmux display-message -d 4000 "fzf-popup: target pane not found: $target_pane"
  exit 1
fi

cmd="$editor $(sq "$file")"

# Send "editor <file>" into the original pane and close the popup.
if ! tmux send-keys -t "$target_pane" -l "$cmd" 2>/dev/null; then
  tmux display-message -d 4000 "fzf-popup: send-keys failed to $target_pane"
  exit 1
fi
tmux send-keys -t "$target_pane" Enter
