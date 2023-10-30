{ config, pkgs, ... }:

{
  home.username = "tmoeller";
  home.homeDirectory = "/home/tmoeller";

  home.stateVersion = "23.05";

  imports = [
    ./packages/commons.nix
  ];

  home.packages = [
    # pkgs.hello
  ];

  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.home-manager.enable = true;
}
