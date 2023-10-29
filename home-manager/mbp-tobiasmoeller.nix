{ config, pkgs, ... }:

{
  home.username = "tobiasmoeller";
  home.homeDirectory = "/Users/tobiasmoeller";

  home.stateVersion = "23.05"; # Please read the comment before changing.

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

  imports = [
    ./packages/commons.nix
  ];
}
