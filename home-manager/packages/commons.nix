{ config, pkgs, lib, ... }:

{
  imports = [
    ./tmux.nix
    ./zsh.nix
    ./nvim.nix
  ];

  home.packages = with pkgs; [
    meslo-lgs-nf # nerd font for powerlevel10k theme
    timewarrior

    # config options: https://nixos.wiki/wiki/PHP
    (php82.buildEnv {
      extensions = ({ enabled, all }: enabled ++ (with all; [
        redis
        imagick
      ]));
      extraConfig = ''
        memory_limit = 500M
      '';
    })
    php82Packages.composer

    nodejs_20

    # LSP packages
    phpactor

    # scripts TODO separate
    (pkgs.writeScriptBin "t" ''
#!/usr/bin/env bash

# Credit to ThePrimeagen

if [[ $# -eq 1 ]]; then
    selected=$1
else
    items+=`find ~/code -maxdepth 2 -mindepth 1 -type d`
    items+=`echo -e "\n$(find ~/portal -maxdepth 2 -mindepth 1 -type d)"`
    items+=`echo -e "\n/tmp"`
    selected=`echo "$items" | fzf`
    # echo "$items"
fi

dirname=`basename $selected | sed 's/\./_/g'`

tmux switch-client -t =$dirname
if [[ $? -eq 0 ]]; then
    exit 0
fi

tmux new-session -c $selected -d -s $dirname && tmux switch-client -t $dirname || tmux new -c $selected -A -s $dirname
    '')
  ];

  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
  };

  home.sessionPath = [
    "$HOME/.composer/vendor/bin"
  ];

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.git = {
    enable = true;
    userName = lib.mkDefault "TobMoeller";
    userEmail = lib.mkDefault "tobiasmoellerw@t-online.de";
    aliases = {
      s = "status -sb";
      st = "status";
      ci = "commit";
      co = "checkout";
      nah = "!git reset --hard && git clean -df";
      alias = "! git config --get-regexp ^alias\. | sed -e s/^alias\.// -e s/\ /\ =\ /";
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.ripgrep = {
    enable = true;
  };

  programs.fzf = {
    enable = true;
  };
}
