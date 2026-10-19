# Reload with: exec zsh
# Home Manager provides completion, history, suggestions and highlighting.
setopt AUTO_CD INTERACTIVE_COMMENTS

# Vi editing: Escape enters command mode; i returns to insert mode.
bindkey -v
KEYTIMEOUT=10
bindkey '^?' backward-delete-char
bindkey '^R' history-incremental-search-backward
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
# Familiar editing shortcuts in insert mode; Escape's vi command mode stays vi.
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^B' backward-char
bindkey -M viins '^F' forward-char
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^Y' yank
bindkey -M viins '^D' delete-char-or-list
bindkey -M viins '^[b' backward-word
bindkey -M viins '^[f' forward-word

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status -sb'

# Optional machine-local additions, outside this repository.
[[ ! -f "$ZDOTDIR/local.zsh" ]] || source "$ZDOTDIR/local.zsh"
