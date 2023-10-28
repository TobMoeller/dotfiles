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

  programs.git = {
    enable = true;
    # includes = [{ path = "./gitconfig"; }];
  };

  # programs.fzf = {
  #   enable = true;
  # };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    prefix = "C-y";
    historyLimit = 10000;
    keyMode = "vi";
  };
}
