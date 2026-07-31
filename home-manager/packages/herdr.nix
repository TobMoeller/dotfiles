{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/code/tobmoeller/dotfiles";
in {
  # The herdr package itself is added in commons.nix (home.packages).

  # Config is symlinked out of the nix store so edits in the repo apply
  # immediately without a home-manager switch. Mirrors the tmux.nix pattern.
  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home-manager/packages/config/herdr/config.toml";
}
