{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/code/tobmoeller/dotfiles";
in {
  # Config-only module. Imported individually by the mbp (macOS) and red (Linux)
  # hosts — deliberately NOT in commons.nix, so the raspi host does not get it.
  # The Ghostty *package* is installed separately:
  #   - red (Linux, non-NixOS): via a nixGL wrapper in red-tobias.nix
  #   - mbp (macOS):            via Homebrew cask (`brew install --cask ghostty`)
  #
  # Symlinked out of the nix store (like herdr/tmux) so edits apply on Ghostty's
  # config reload (ctrl/cmd+shift+,) without a home-manager switch.
  xdg.configFile."ghostty/config".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home-manager/packages/config/ghostty/config";
}
