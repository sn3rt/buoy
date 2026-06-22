# buoy

Terminal-focused dotfiles for multiple Linux machines.

This repo intentionally stays portable. Desktop/session-specific config lives
outside this repo.

## Install

Run:

```bash
./install.sh
```

This script creates symlinks from this repo into `$HOME` and moves any existing conflicting files into `~/.buoy-backup/<timestamp>/`.

It links config/scripts only. To install the tools themselves at the versions pinned in `versions.toml`, run:

```bash
./install-tools.sh
```

This downloads pinned tools from GitHub releases into `~/.local/bin/`, including `eza` for the `ls` wrapper. Most tools use prebuilt binaries; tmux is built from source. Skips tools already installed at the pinned version; use `--force` to re-download. Requires `curl`, `tar`, `gzip`, `bzip2`, and `unzip`. Building tmux on Ubuntu/Debian also requires `build-essential`, `pkg-config`, `libevent-dev`, and `libncurses-dev`. Neovim Treesitter parser builds also require a C compiler.

To check whether newer pinned tool versions are available:

```bash
./update-versions.sh          # check all tools and ask before updating versions.toml
./update-versions.sh --write  # update versions.toml without asking
./install-tools.sh --update
```

## Temporary remote shell

If you want to SSH into another machine with these buoy config for just that session, use `nomad` instead of installing the repo there:

```bash
nomad user@host
nomad --waypipe user@host
nomad -wp user@host
```

What it does:

- packs this repo locally and streams it to the remote host
- unpacks into a temporary directory on the remote host
- starts `zsh` with `ZDOTDIR` and the XDG paths pointed at that temporary copy
- reuses that temporary directory on later `nomad` connections to the same host

Notes:

- the remote host needs `zsh`, `tar`, and `mktemp`
- `nomad` is for an interactive shell only; it does not support passing a remote command
- `nomad` just opens a normal interactive SSH session; start `tmux` on the remote host yourself if you want it there
- `nomad --waypipe` / `nomad -wp` starts the final shell through Waypipe so Wayland GUI apps launched remotely can open locally
- `wp user@host` is a shortcut for `waypipe ssh user@host` without nomad's temporary dotfiles
- Waypipe mode requires `waypipe` on both the local and remote machine
- normal `exit` keeps the temporary directory alive so another terminal can reconnect to it
- run `damon` inside the `nomad` shell to remove the temporary dotfiles and leave the SSH session
- config, cache, logs, and tools installed with `./install-tools.sh` stay in that temporary directory until `damon`, reboot, or remote `/tmp` cleanup removes it
- set `DOTFILES_DIR` if you want `nomad` to use a repo path other than the one inferred from the script location

## Secrets

Create `~/.config/secrets/.zshenv` (not tracked by git). Example:

```bash
cp .config/secrets/.zshenv.example ~/.config/secrets/.zshenv
$EDITOR ~/.config/secrets/.zshenv
```

## Theme colors

Kitty colors are included with this repo.

Neovim uses terminal palette slots instead of hardcoded hex colors, so live
Kitty palette updates also affect Neovim. Running `:BuoyThemeReload` inside
Neovim reapplies the highlight mappings if another colorscheme overwrites them.

## Git helper

Use `gt "message"` to run `git status --short`, `git add .`, and `git commit -m "message"`.
Use `gt -p "message"` to push after committing when the current branch already has an upstream.

## tmux

Config lives in `~/.config/tmux/tmux.conf` and is also linked to `~/.tmux.conf` for compatibility.

New terminals open as a normal shell. Use `tmx` when you want a tmux session:

- `tmx`: create/attach a session for the current directory
- `tmx /path/to/project`: create/attach a session for that directory
- Session names use the directory name plus a short path hash to avoid collisions
- On remote hosts, start tmux there manually if you want sessions/popups

- `Alt+p`: open Codex in a floating popup
- In the popup: `Alt+c` hides the popup (Codex keeps running; press `Alt+p` again to reopen)
- `Alt+b`: open Claude in a floating popup
- In the popup: `Alt+c` hides the popup (Claude keeps running; press `Alt+b` again to reopen)
- `Alt+e`: open Yazi in a floating popup
- In the popup: `Alt+c` closes the popup; `q` closes Yazi and the popup
- `Alt+f`: open a file fuzzy finder (fzf) in a popup; `Enter` opens the selection in `$EDITOR` in the original pane

Codex/Claude popups are isolated per tmux session (so you can have multiple running at once across sessions). Yazi and fzf are short-lived popups.
Yazi uses the same popup path locally and inside a `nomad` remote shell.

These popups need the underlying tools installed on that machine (`codex`, `claude`, `yazi`, `fzf`; `fd` is optional for the file picker).
