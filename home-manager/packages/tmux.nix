{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/code/tobmoeller/dotfiles";
in {
  home.packages = [ pkgs.tmux ];

  # The config is symlinked out of the nix store so edits in the repo apply
  # immediately ('PREFIX r' reloads) without a home-manager switch.
  # Replaces the previous programs.tmux module; its options now live as plain
  # tmux commands at the top of tmux.conf.
  xdg.configFile."tmux/tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home-manager/packages/config/tmux/tmux.conf";
}
