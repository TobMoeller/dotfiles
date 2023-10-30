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
    userName = "TobMoeller";
    userEmail = "tobiasmoellerw@t-online.de";
    aliases = {
      s = "status -sb";
      st = "status";
      ci = "commit";
      co = "checkout";
      nah = "!git reset --hard && git clean -df";
      alias = "! git config --get-regexp ^alias\. | sed -e s/^alias\.// -e s/\ /\ =\ /";
    };
  };

  # programs.fzf = {
  #   enable = true;
  # };

}
