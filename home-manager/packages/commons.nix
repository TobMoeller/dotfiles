{ config, pkgs, lib, ... }:

{
  imports = [
    ./tmux.nix
    ./zsh.nix
    ./nvim.nix
  ];

  # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "intelephense"
  ];

  home.packages = with pkgs; [
    meslo-lgs-nf # nerd font for powerlevel10k theme
    timewarrior
    jq # command line json processor

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
    python3

    # LSP packages
    phpactor
    nodePackages.volar
    nodePackages.intelephense
    nodePackages.pyright
    nodePackages."@tailwindcss/language-server" # (not found in nix packages: https://github.com/NixOS/nixpkgs/issues/200244)

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
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
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
