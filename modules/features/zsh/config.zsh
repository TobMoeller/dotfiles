# Reload with: exec zsh
# Home Manager provides completion, history, suggestions and highlighting.
setopt AUTO_CD INTERACTIVE_COMMENTS

# Vi editing: Escape enters command mode; i returns to insert mode.
bindkey -v
KEYTIMEOUT=10
bindkey '^?' backward-delete-char
bindkey '^R' history-incremental-search-backward
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^F' forward-char

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status -sb'

# A small prompt using only zsh's built-in Git integration.
autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' (%b)'
add-zsh-hook precmd vcs_info
setopt PROMPT_SUBST
PROMPT='%F{cyan}%~%f%F{yellow}${vcs_info_msg_0_}%f %(?.%F{green}.%F{red})%#%f '

# Optional machine-local additions, outside this repository.
[[ ! -f "$ZDOTDIR/local.zsh" ]] || source "$ZDOTDIR/local.zsh"
