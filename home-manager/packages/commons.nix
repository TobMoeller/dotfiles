{ config, pkgs, ... }:

{
  imports = [
    ./tmux.nix
    ./zsh.nix
  ];

  home.packages = [
    pkgs.meslo-lgs-nf
    pkgs.timewarrior
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
