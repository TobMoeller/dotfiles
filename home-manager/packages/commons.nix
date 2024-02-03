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

    (pkgs.writeShellScriptBin "t" (builtins.readFile ./scripts/t))
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
