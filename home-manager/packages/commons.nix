{ config, pkgs, ... }:

{
  imports = [
    ./tmux.nix
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

  programs.git = {
    enable = true;
    # includes = [{ path = "./gitconfig"; }];
  };

  # programs.fzf = {
  #   enable = true;
  # };

}
