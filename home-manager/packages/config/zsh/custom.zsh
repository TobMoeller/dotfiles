# Custom zsh additions — tracked in git, symlinked into place from the dotfiles
# repo via home.file + mkOutOfStoreSymlink (see zsh.nix). Because it's a symlink
# to the working tree (not the nix store), edits here take effect in any new
# shell — no `home-manager switch` required. Reload the current shell with:
#   source ~/.zsh/custom.zsh   (or: exec zsh)
#
# Put anything here: aliases, functions, exports, keybinds. Stable config that
# rarely changes still belongs in zsh.nix (shellAliases, plugins, etc.).

# Aliases
# alias gs='git status'

# Functions
# mkcd() { mkdir -p "$1" && cd "$1"; }
