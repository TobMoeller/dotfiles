{ config, pkgs, ... }:

{
  home.username = "tobiasmoeller";
  home.homeDirectory = "/Users/tobiasmoeller";

  home.stateVersion = "23.11";

  imports = [
    ./packages/commons.nix
    ./packages/alacritty.nix
  ];

  home.packages = with pkgs; [
    # pkgs.hello
    zig_0_13
    zls
  ];

  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.home-manager.enable = true;
}
