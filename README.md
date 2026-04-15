# dotfiles

Terminal-focused dotfiles for multiple Linux machines.

## Install

Run:

```bash
./install.sh
```

This script creates symlinks from this repo into `$HOME` and moves any existing conflicting files into `~/.dotfiles-backup/<timestamp>/`.

## Temporary remote shell

If you want to SSH into another machine with these dotfiles for just that session, use `ssht` instead of installing the repo there:

```bash
ssht user@host
```

What it does:

- packs this repo locally and streams it to the remote host
- unpacks into a temporary directory on the remote host
- starts `zsh` with `ZDOTDIR` and the XDG paths pointed at that temporary copy
- removes the temporary directory again when the session exits

Notes:

- the remote host needs `zsh`, `tar`, and `mktemp`
- `ssht` is for an interactive shell only; it does not support passing a remote command
- `ssht` just opens a normal interactive SSH session; start `tmux` on the remote host yourself if you want it there
- set `DOTFILES_DIR` if you want `ssht` to use a repo path other than the one inferred from the script location

## Secrets

Create `~/.config/secrets/.zshenv` (not tracked by git). Example:

```bash
cp .config/secrets/.zshenv.example ~/.config/secrets/.zshenv
$EDITOR ~/.config/secrets/.zshenv
```

## OpenCode plugins

Plugin manifests are tracked (`~/.config/opencode/package.json`, `~/.config/opencode/bun.lock`) but the actual install is local.
Install/update plugins on a machine by running your package manager (e.g. `bun install`) inside `~/.config/opencode/`.

## tmux

Config lives in `~/.config/tmux/tmux.conf` and is also linked to `~/.tmux.conf` for compatibility.

New terminals open as a normal shell. Use `tmx` when you want a tmux session:

- `tmx`: create/attach a session for the current directory
- `tmx /path/to/project`: create/attach a session for that directory
- Session names use the directory name plus a short path hash to avoid collisions
- Popup keys are local-only; on remote hosts, start tmux there manually if you want popups/sessions

- `Alt+o`: open OpenCode in a floating popup (requires tmux `display-popup`, tmux >= 3.2)
- In the popup: `Alt+c` hides the popup (OpenCode keeps running; press `Alt+o` again to reopen)
- `Alt+e`: open Yazi in a floating popup
- In the popup: `Alt+c` hides the popup (Yazi keeps running; press `Alt+e` again to reopen)
- `Alt+f`: open a file fuzzy finder (fzf) in a popup; `Enter` opens the selection in `$EDITOR` in the original pane

OpenCode/Yazi popups are isolated per tmux session (so you can have multiple running at once across sessions).
