# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Shell and terminal tool configs for multiple Linux machines: zsh, tmux, nvim, starship, atuin, kitty, yazi, fzf, btop, Claude Code, OpenCode. Desktop/WM configs (Hyprland, etc.) are out of scope.

All files are symlinked into `$HOME` by `install.sh` — editing files here edits the live config.

## Installing / re-linking configs

```bash
./install.sh
```

Idempotent. Backs up any conflicting files to `~/.buoy-backup/<timestamp>/` before creating symlinks.

## Installing tools

```bash
./install-tools.sh          # install all tools listed in versions.toml
./install-tools.sh nvim     # install one tool
./install-tools.sh --update # re-download everything
```

Tool versions are pinned in `versions.toml`. Skips tools already present on `$PATH` or in `~/.local/bin/`. Requires `curl`, `tar`, `unzip`.

## Key files and their roles

| Path | Role |
|---|---|
| `.zshrc` | Shell entrypoint: zinit plugins, PATH, aliases, starship, atuin |
| `.config/tmux/tmux.conf` | Main tmux config; sources popup keybinds |
| `.config/tmux/tmx` | Session manager script (used via `.local/bin/tmx`) |
| `.config/tmux/popup-dispatch.sh` | Routes `Alt+o/b/e/f` keypresses to the right popup |
| `.config/tmux/popup-server.sh` | Starts/attaches a dedicated tmux server per outer session for long-running popup tools |
| `.config/tmux/{opencode,codex,claude}.conf` | Minimal tmux configs for each long-running popup server |
| `.config/tmux/yazi-popup.sh` | Short-lived Yazi popup launcher with previews disabled |
| `.config/tmux/fzf-popup.sh` | fzf file picker; sends `$EDITOR <file>` to the originating pane |
| `.local/bin/ssht` | SSH into a remote host using a temporary copy of this repo |
| `setup-remote-user.sh` | One-time setup of a personal Unix account on a shared team machine |
| `.config/secrets/.zshenv.example` | Template for secrets (not tracked); copy to `~/.config/secrets/.zshenv` |
| `.config/opencode/opencode.json` | OpenCode config (tracked); `node_modules` is machine-local |

## Popup architecture

Long-running popup tools (opencode, codex, claude) run inside their own dedicated tmux server, isolated per outer tmux session. Yazi and fzf are short-lived direct popups that use the same path locally and under `ssht`.

1. **tmux keybind** (`Alt+o/p/b/e/f`) → calls `popup-dispatch.sh` with the outer session id and cwd
2. **`popup-dispatch.sh`** → calls `tmux display-popup`, either through `popup-server.sh` for long-running tools or directly for short-lived tools
3. **`popup-server.sh`** → starts or attaches a tmux server named `<tool>-<outer_session_id>` and launches the tool
   - For opencode: queries the opencode SQLite DB to resume the most recent session for the cwd
   - For claude: finds the latest `.jsonl` in `~/.claude/projects/<cwd-as-path>/` to `--resume` a session
4. `Alt+c` inside OpenCode/Codex/Claude detaches the inner client; Yazi closes with its normal `q` binding

## ssht — temporary remote dotfiles

`ssht user@host` packs this repo with `tar --exclude-vcs`, streams it to a temp dir on the remote, then starts a login zsh with `ZDOTDIR` and all XDG vars pointing at that temp dir. The temp dir is removed when the session exits.

- Set `DOTFILES_DIR` to override the repo path inferred from the script location
- Remote needs `zsh`, `tar`, `mktemp`
- Does not support passing a remote command

## Secrets

`~/.config/secrets/.zshenv` is sourced by `.zshrc` but not tracked by git. Copy `.config/secrets/.zshenv.example` to get started.

## OpenCode plugins

After cloning or pulling, run the package manager inside `~/.config/opencode/` to install/update plugins:

```bash
cd ~/.config/opencode && bun install
```
