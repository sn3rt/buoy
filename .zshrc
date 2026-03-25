# Set directory for zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download zinit if not present
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# If on TTY, launch Hyprland
# if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
if [ -z "${DISPLAY-}" ] && [ "${XDG_VTNR-}" = "1" ]; then
  # exec hyprland
  exec start-hyprland
fi

# Source zinit
source "${ZINIT_HOME}/zinit.zsh"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.nix-profile/bin:$PATH"
export EDITOR="nvim"
export GOPATH="$HOME/.local/share/go"

# Optional secrets (not tracked in dotfiles)
[[ -f "$HOME/.config/secrets/.zshenv" ]] && source "$HOME/.config/secrets/.zshenv"

# Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit ice lucid wait'0'
zinit light joshskidmore/zsh-fzf-history-search
# Rebind Up arrow to trigger fzf history search
# bindkey '^[[A' zsh-fzf-history-search

# Shell integration (fzf)
[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

# Load completions
autoload -Uz compinit
compinit

# Enable Starship prompt
eval "$(starship init zsh)"

# Keybindings
bindkey -v
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion style
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zcompdump

# Aliases
alias ls='ls --color'
alias la='ls -a --color'
alias ll='ls -an --color'
alias vi='nvim'
alias vim='nvim'
alias snert='cat "$HOME/.config/snert-logo"'

alias rdp='~/.scripts/rdp_connect.sh'

#alias pvim='nvim -u .config/pvim/init.lua'


[[ -f "$HOME/.atuin/bin/env" ]] && . "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"
