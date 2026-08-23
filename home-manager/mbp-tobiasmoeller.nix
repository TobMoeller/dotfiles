{ config, pkgs, ... }:

{
  home.username = "tobiasmoeller";
  home.homeDirectory = "/Users/tobiasmoeller";

  home.stateVersion = "23.11";

  imports = [
    ./packages/commons.nix
    ./packages/alacritty.nix
    # Ghostty config only. Install the app itself on macOS via Homebrew:
    #   brew install --cask ghostty
    ./packages/ghostty.nix
    # Same deal: docs and .stignore only, the app comes from Homebrew:
    #   brew install --cask syncthing-app
    ./packages/syncthing.nix
  ];

  home.packages = with pkgs; [
    # pkgs.hello
    zig
    zls
  ];

  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.home-manager.enable = true;

  home.sessionPath = [
    "/opt/homebrew/bin"
  ];
}
