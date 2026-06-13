# buoy

Terminal-focused dotfiles for multiple Linux machines.

This repo intentionally stays portable. Desktop/session-specific config such as
Hyprland, Quickshell, wallpaper selection, and live theme generation
lives in the separate quay repo.

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

This downloads binaries from GitHub releases into `~/.local/bin/`. Skips tools already installed; use `--update` to force re-download. Requires `curl`, `tar`, `gzip`, `bzip2`, and `unzip`. Neovim Treesitter parser builds also require a C compiler.

## Shared team machines

If multiple people share a single Ubuntu user account, each person should have their own
Unix account so credentials and configs stay private. Run this once per person (requires
sudo on the remote machine):

```bash
sudo ./setup-remote-user.sh <shared-user> <personal-user> [--ssh-key "pubkey"] [project-dir ...]
```

What it does:

- creates the personal user account (if it doesn't exist)
- adds them to the shared user's group so they can read the shared home
- locks down the personal home dir (mode 700) so others cannot read it
- optionally adds an SSH public key and sets up project dirs with group write access

After that each person clones this repo into their own home and runs `./install.sh` +
`./install-tools.sh` to get their own tools and configs, including their own Claude Code
credentials.

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
- removes the temporary directory again when the session exits

Notes:

- the remote host needs `zsh`, `tar`, and `mktemp`
- `nomad` is for an interactive shell only; it does not support passing a remote command
- `nomad` just opens a normal interactive SSH session; start `tmux` on the remote host yourself if you want it there
- `nomad --waypipe` / `nomad -wp` starts the final shell through Waypipe so Wayland GUI apps launched remotely can open locally
- Waypipe mode requires `waypipe` on both the local and remote machine
- config, cache, and logs written during the session stay in that temporary directory and are removed when the session ends
- tools installed with `./install-tools.sh` inside a `nomad` session go into the same temporary directory and are removed when the session ends
- set `DOTFILES_DIR` if you want `nomad` to use a repo path other than the one inferred from the script location

## Secrets

Create `~/.config/secrets/.zshenv` (not tracked by git). Example:

```bash
cp .config/secrets/.zshenv.example ~/.config/secrets/.zshenv
$EDITOR ~/.config/secrets/.zshenv
```

## Theme colors

Terminal and Neovim colors are read from `~/.config/buoy-theme/kitty.conf`,
which is linked from `.config/buoy-theme/kitty.conf` in this repo.

The quay repo owns the wallpaper palette generator. When you run its
`theme-wallpaper` script, it updates the generated shared theme inside this
`dots` checkout. Commit and push that generated file when you want new terminal
and Neovim colors to follow `dots` to other machines.

Machines that only install `dots` use the last committed shared theme. They do
not need Hyprland, Quickshell, Pillow, or wallpaper tooling.

Neovim uses terminal palette slots instead of hardcoded hex colors, so live
Kitty palette updates also affect Neovim. Running `:BuoyThemeReload` inside
Neovim reapplies the highlight mappings if another colorscheme overwrites them.

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
