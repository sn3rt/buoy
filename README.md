# buoy

Dotfiles for portable terminal environments and an optional Arch/Hyprland desktop.

The terminal profile is the portable base used locally and by Nomad. The desktop
profile adds Hyprland, Quickshell, desktop helpers, and desktop-specific Yazi
behavior on top of it.

## Install

Link the terminal profile (the default):

```bash
./install.sh
./install.sh --terminal
```

Link the terminal and desktop profiles:

```bash
./install.sh --desktop
```

The installer creates symlinks from this repo into `$HOME` and moves conflicting
files into `~/.buoy-backup/<timestamp>/`. It only links configuration; it does not
install software.

Profile contents are defined in `profiles/terminal.links` and
`profiles/desktop.links`.

## Tools

Install the terminal tools pinned in `versions.toml`:

```bash
./install-tools.sh
./install-tools.sh --terminal
```

On Arch, install the desktop package set plus the pinned terminal tools:

```bash
./install-tools.sh --desktop
```

Desktop packages are read from `profiles/desktop.packages` and installed with
`pacman -S --needed`. Pacman owns and updates those packages. The script does not
enable services, install hardware drivers, or install the configured Zen Browser
Flatpak.

Pinned terminal tools are installed into `~/.local/bin/` so local machines and
Nomad use the same versions. Most use release binaries; tmux is built from source.
Exact installed versions are skipped, while `--force` downloads them again.

Terminal mode requires `curl`, `tar`, `gzip`, `bzip2`, and `unzip`. Building tmux
on Ubuntu/Debian also requires `build-essential`, `pkg-config`, `libevent-dev`, and
`libncurses-dev`. Neovim Treesitter parser builds require a C compiler.

To check whether newer pinned tool versions are available:

```bash
./update-versions.sh          # check all tools and ask before updating versions.toml
./update-versions.sh --write  # update versions.toml without asking
./install-tools.sh --update
```

`update-versions.sh` is the controlled update path for terminal pins. Normal
`pacman -Syu` updates the desktop package set.

## Temporary remote shell

If you want to SSH into another machine with these buoy config for just that session, use `nomad` instead of installing the repo there:

```bash
nomad user@host
nomad --waypipe user@host
nomad -wp user@host
```

What it does:

- builds a payload from the tracked terminal profile and streams it to the remote host
- unpacks into a temporary directory on the remote host
- starts `zsh` with `ZDOTDIR` and the XDG paths pointed at that temporary copy
- reuses that temporary directory on later `nomad` connections to the same host

Notes:

- the local host needs `git`; the remote host needs `zsh`, `tar`, and `mktemp`
- `nomad` is for an interactive shell only; it does not support passing a remote command
- `nomad` just opens a normal interactive SSH session; start `tmux` on the remote host yourself if you want it there
- `nomad --waypipe` / `nomad -wp` starts the final shell through Waypipe so Wayland GUI apps launched remotely can open locally
- `wp user@host` is a shortcut for `waypipe ssh user@host` without nomad's temporary dotfiles
- Waypipe mode requires `waypipe` on both the local and remote machine
- normal `exit` keeps the temporary directory alive so another terminal can reconnect to it
- run `damon` inside the `nomad` shell to remove the temporary dotfiles and leave the SSH session
- desktop configuration is never included in the Nomad payload
- config, cache, logs, and tools installed with `./install-tools.sh --terminal` stay in that temporary directory until `damon`, reboot, or remote `/tmp` cleanup removes it
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

On the desktop, `theme-wallpaper` updates the wallpaper and live Kitty, tmux,
Hyprland, and Quickshell colors from the generated palette.

## Git helper

Use `gt "message"` to run `git status --short`, `git add .`, and `git commit -m "message"`.
Use `gt -p "message"` to push after committing when the current branch already has an upstream.

## tmux

Config lives in `~/.config/tmux/tmux.conf` and is also linked to `~/.tmux.conf` for compatibility.

Use `tmx [path]` to create or attach a tmux session for a directory.

Pane/window keys:

- `Alt+h/j/k/l`: focus pane left/down/up/right
- `Alt+Shift+h/j/k/l`: swap pane left/down/up/right
- `Alt+q`: split pane right; `Alt+Shift+q`: split pane down
- `Alt+t`: toggle panes between side-by-side and stacked
- `Alt+x`: close pane
- `Alt+u/o`: previous/next tmux window
- `Alt+Ctrl+h/l`: move pane to previous/next tmux window

Popups:

- `Alt+p`: Codex
- `Alt+b`: Claude
- `Alt+e`: Yazi
- `Alt+f`: fzf file picker

`Alt+c` closes the active popup. Codex and Claude keep running in their isolated tmux popup sessions; Yazi and fzf are short-lived. The popup tools need to be installed on the machine where tmux is running.
