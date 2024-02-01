{ config, pkgs, ... }:

{
  home.username = "tmoeller";
  home.homeDirectory = "/home/tmoeller";

  home.stateVersion = "23.05";

  imports = [
    ./packages/commons.nix
  ];

  home.packages = with pkgs; [
    # pkgs.hello
    podman # requires uidmap on ubuntu
    podman-compose

    chromium
    ghostscript
  ];

  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
    ".ideavimrc".source = ./packages/config/ideavimrc;
  };

  home.sessionPath = [
    "/snap/bin"
  ];

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.home-manager.enable = true;

  programs.git = {
    userName = "eptmoeller";
    userEmail = "tobias.moeller@ecoplan.de";
  };
}
