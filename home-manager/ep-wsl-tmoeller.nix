{ config, pkgs, ... }:

{
  home.username = "tmoeller";
  home.homeDirectory = "/home/tmoeller";

  home.stateVersion = "23.11";

  imports = [
    ./packages/commons.nix
  ];

  home.packages = with pkgs; [
    # pkgs.hello
    podman # requires uidmap on ubuntu
    podman-compose
    slirp4netns # required for podman networking

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

  programs.git.settings = {
    user.name = "eptmoeller";
    user.email = "tobias.moeller@ecoplan.de";
  };
}
