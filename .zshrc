# Set directory for zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download zinit if not present
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

if [[ "${TERM-}" == "xterm-kitty" ]] && ! infocmp xterm-kitty >/dev/null 2>&1; then
  export TERM="xterm-256color"
fi

if [ -z "${DISPLAY-}" ] && [ "${XDG_VTNR-}" = "1" ]; then
  exec start-hyprland
fi

# Source zinit
source "${ZINIT_HOME}/zinit.zsh"
export PATH="${XDG_BIN_HOME:-$HOME/.local/bin}:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.nix-profile/bin:$PATH"
export EDITOR="nvim"

# Optional secrets (not tracked in dotfiles)
[[ -f "$HOME/.config/secrets/.zshenv" ]] && source "$HOME/.config/secrets/.zshenv"

# Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit ice lucid wait'0'
zinit light joshskidmore/zsh-fzf-history-search

# Shell integration (fzf)
[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

# Load completions
autoload -Uz compinit
compinit

export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"

# Enable Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Keybindings
bindkey -v
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
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
alias ll='ls -aln --color'
alias sudo='sudo '

alias vi='nvim'
alias vim='nvim'

alias snert='cat "$HOME/.config/snert-logo"'
alias rdp='~/.scripts/rdp_connect.sh'

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# opencode
export PATH="$HOME/.opencode/bin:$HOME/.local/share/opencode/bin:$PATH"
