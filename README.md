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

Before reinstalling, [ARCH-REINSTALL.md](ARCH-REINSTALL.md) lists the small set
of identity and connection files worth copying.

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

Hexe is currently a local-only desktop pilot. `./install-tools.sh --desktop`
includes it, and `./install-tools.sh hexe` installs only Hexe. The default
terminal tool list used by Nomad intentionally does not install it yet.

Before downloading anything, terminal mode checks its host dependencies,
including Zsh, Git, SSH, ripgrep, archive tools, and the tmux build toolchain. If
anything is missing, it prints one complete `pacman` or `apt` command and stops;
install those packages and run `install-tools.sh` again. On Ubuntu/Debian the
tmux dependencies include `bison` (which provides `yacc`), `build-essential`,
`pkg-config`, `libevent-dev`, and `libncurses-dev`. On Arch they are provided by
`base-devel`, `pkgconf`, `libevent`, and `ncurses`.

The installer does not silently change the account login shell or log out an SSH
session. After a successful full-profile install it prints these commands when
Zsh is not already the login shell:

```bash
chsh -s "$(command -v zsh)" # use Zsh on future logins
exec zsh -l                 # replace the current shell now
```

Do not source `.zshrc` from Bash. The file is Zsh syntax; its guard will point
you to `exec zsh -l` instead.

To check whether newer pinned tool versions are available:

```bash
./update-versions.sh          # check all tools and ask before updating versions.toml
./update-versions.sh --write  # update versions.toml without asking
./install-tools.sh --update
```

`update-versions.sh` is the controlled update path for terminal pins. Normal
`pacman -Syu` updates the desktop package set.

## Skillshare

[Skillshare](https://github.com/runkids/skillshare) keeps one skill source and
syncs it into the directories used by AI coding tools. Buoy tracks that source
at `~/.config/skillshare/skills` and uses merge mode to expose each skill in:

- `~/.agents/skills` for Codex and other tools that support the universal path
- `~/.claude/skills` for Claude Code

The default tool install includes the pinned Skillshare CLI. To install only it,
link the config, audit the source, preview the first sync, and apply it:

```bash
./install-tools.sh skillshare
./install.sh
skillshare audit --global
skillshare sync --global --dry-run
skillshare sync --global
skillshare status --global
```

Run `skillshare ui --global` for the local web dashboard. Its UI assets are
downloaded and cached on first launch.

`ss` is an alias for `skillshare`, and Zsh completion is loaded when the binary
is available. Start a new Codex or Claude session after the first sync if its
skill list was already loaded.

Two global skills are included initially. Use `$skillshare` in Codex when you
want the agent to manage or troubleshoot Skillshare. Use `$lua-config-api` when
designing, converting, or reviewing an embedded-Lua API for a tool you control,
its plugin discovery convention, or its cross-process API. The Lua skill is not
for editing third-party configuration such as Neovim. Both skills can also be
selected implicitly when the request clearly matches their descriptions.

Global skills are already available while working in any project; no per-project
setup is required for them. For knowledge or workflows that belong to one repo,
initialize project mode from that repo instead:

```bash
skillshare init -p --targets universal,claude --mode merge
skillshare new project-conventions -p --pattern none
$EDITOR .skillshare/skills/project-conventions/SKILL.md
```

Add Skillshare's generated target views to the project's `.gitignore`:

```gitignore
.agents/skills/
.claude/skills/
```

Then validate, deploy, and commit the source:

```bash
skillshare audit -p
skillshare sync -p --dry-run
skillshare sync -p
git add .skillshare .gitignore
```

Commit `.skillshare/`, which is the project's source of truth, and ignore the
generated `.agents/skills/` and `.claude/skills/` target views; do not copy a
global skill into every project. Teammates install Skillshare, run
`skillshare install -p` when the project config lists remote skills, and then run
`skillshare sync -p`.

For normal maintenance, run `skillshare check`, `skillshare audit`, and
`skillshare sync`. To add a newly installed AI tool, run
`skillshare init --discover` and select the actual tool. Avoid blindly adding all
detected targets: stale config directories can be detected as tools, and adding
both `codex` and `universal` can make the same skill appear twice in Codex.

Buoy owns the global source repository and pins the CLI, so do not use global
`skillshare commit`, `push`, `pull`, or `upgrade` here. Use normal Git for Buoy
changes. Update the CLI with `./update-versions.sh --write skillshare` followed
by `./install-tools.sh skillshare`, and refresh the bundled management skill
from the matching release tag while retaining its Codex compatibility change.

The Lua skill is deliberately vendored and does not update through
`skillshare check`. Its permitted source revision, and the source revision for
the bundled Skillshare management skill, are recorded in
[`.config/skillshare/SOURCES.md`](.config/skillshare/SOURCES.md).

## Monitor layout

`hypr-monitors-auto` defaults to placing the laptop below the external
display row, aligned left. The optional `left` layout places the laptop to
the left of the first external display, with their bottom edges aligned.
External displays continue to the
right in stable DP/HDMI order; automatic DPI scaling is retained. With only
the laptop connected, it stays at `(0,0)`.

Apply either layout manually:

```bash
hypr-monitors-auto left   # laptop left, bottom edges aligned
hypr-monitors-auto below  # laptop below the external row, aligned left (default)
```

The argument overrides one run. To change the layout used on startup,
reconnection, and config reload, edit `LAPTOP_POSITION` near the top of
`.local/bin/hypr-monitors-auto`.

## Audio output

The desktop profile includes an output switcher for the built-in laptop
speakers and the ThinkPad USB-C dock:

```bash
audio-output laptop
audio-output dock
audio-output toggle
audio-output status
```

Selecting an output also moves current playback streams. WirePlumber remembers
the selected laptop Speaker profile and default sink across restarts.

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
- starts `zsh` when available, otherwise Bash, with the XDG paths pointed at that temporary copy
- reuses that temporary directory on later `nomad` connections to the same host

Notes:

- the local host needs `git`; the remote host needs either `zsh` or Bash, plus `tar` and `mktemp`
- Bash fallback sessions keep the Buoy prompt, tools, aliases, history, Atuin, and Direnv, but omit zsh-only Zinit plugins such as autosuggestions and `fzf-tab`
- `nomad` is for an interactive shell only; it does not support passing a remote command
- `nomad` just opens a normal interactive SSH session; start `tmux` on the remote host yourself if you want it there
- `nomad --waypipe` / `nomad -wp` starts the final shell through Waypipe so Wayland GUI apps launched remotely can open locally
- `wp user@host` is a shortcut for `waypipe ssh user@host` without nomad's temporary dotfiles
- Waypipe mode requires `waypipe` on both the local and remote machine
- normal `exit` keeps the temporary directory alive so another terminal can reconnect to it
- run `damon` inside the `nomad` shell to remove the temporary dotfiles and leave the SSH session
- Codex uses `CODEX_HOME` inside the temporary directory, so Nomad-scoped Codex logins, configuration, and sessions are removed by `damon`
- credentials created outside Nomad in the remote account's normal `~/.codex` are not moved or removed
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

The generated theme supports persistent dark and light variants derived from
the same wallpaper palette:

```bash
theme-wallpaper --dark
theme-wallpaper --light
theme-wallpaper --toggle
```

Changing mode keeps the current wallpaper. Later wallpaper changes retain the
selected mode.

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

## Hexe (local pilot)

[Hexe](https://github.com/termworks/hexe) is installed alongside tmux; it does
not replace `tmx` or change any tmux session. Use `hxe [path]` to create or
reattach the Hexe session rooted at a directory. Run native Hexe commands with
`hexe`, for example `hexe session list` and `hexe config check`.

Hexe uses a compact Starship-like prompt only inside Hexe panes. Normal shells,
tmux, and Nomad continue to use Starship. Its bottom bar shows the session and
focused pane, open tabs, a running-command animation, and date/time. All Hexe
colors use Buoy's generated terminal palette. Hexe sessions and sticky floats
survive frontend detach/restart; their state lives below
`${XDG_STATE_HOME:-~/.local/state}/hexe`.

Pane/tab keys:

- `Alt+h/j/k/l` or `Alt+Arrow`: focus panes
- `Alt+q` / `Alt+Shift+q`: horizontal/vertical split
- `Alt+x`: close pane with confirmation
- `Alt+u/o`: previous/next tab
- `Alt+s`: label panes; lowercase focuses and uppercase swaps
- `Alt+z`: zoom pane
- `Alt+/`: search scrollback; `Alt+y`: keyboard copy mode
- `Alt+r`: reload Hexe config
- `Ctrl+Alt+p`: toggle a random Pokémon sprite in the focused pane
- `Ctrl+Alt+d`: detach and leave the session running

Native persistent floats:

- `Alt+p`: Codex
- `Alt+b`: Claude
- `Alt+e`: Yazi, using the normal Yazi config and Kitty image previews
- `Alt+f`: fzf file picker; the selected file opens in the creator pane
- `Alt+c`: hide the focused configured float without killing its process

Current parity differences: Hexe uses `Alt+s` plus an uppercase pane label
instead of directional `Alt+Shift+h/j/k/l` swaps; it has no equal-layout action
for tmux's `Alt+t`; and it uses disown/adopt rather than directly moving a pane
to an adjacent tab. Run `hxe` outside Hexe; detach first when changing rooted
sessions.

Hexe also supports project `.hexe.lua` layouts, saved-layout freeze/restore,
pane recording, synchronized input, notifications, and Linux namespace/cgroup
isolation. Those are deliberately left out of this first local parity pilot.
