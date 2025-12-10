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
    "ngrok"
  ];

  home.packages = with pkgs; [
    hyperfine
    meslo-lgs-nf # nerd font for powerlevel10k theme
    timewarrior
    jq # command line json processor
    minikube

    # config options: https://nixos.wiki/wiki/PHP
    (php84.buildEnv {
      extensions = ({ enabled, all }: enabled ++ (with all; [
        redis
        imagick
        # pcov
        # rdkafka
        # mongodb
      ]));
      extraConfig = ''
        memory_limit = 500M
      '';
    })
    php84Packages.composer

    nodejs_24
    python3

    # LSP packages
    phpactor
    typescript
    typescript-language-server
    vue-language-server
    tailwindcss-language-server
    intelephense
    pyright

    (pkgs.writeShellScriptBin "t" (builtins.readFile ./scripts/t))
  ];

  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
    ".npmrc".text = "prefix=${config.home.homeDirectory}/.npm-global";
  };

  home.sessionPath = [
    "$HOME/.composer/vendor/bin"
    "$HOME/.config/composer/vendor/bin"
    "$HOME/.npm-global/bin"
    "$HOME/bin"
  ];

  home.sessionVariables = {
    VUE_PLUGIN_PATH = "${pkgs.vue-language-server}/lib/node_modules/@vue/language-server";
    # EDITOR = "emacs";
  };

  programs.git = {
    enable = true;
    aliases = {
      s = "status -sb";
      st = "status";
      ci = "commit";
      co = "checkout";
      nah = "!git reset --hard && git clean -df";
      alias = "! git config --get-regexp ^alias\. | sed -e s/^alias\.// -e s/\ /\ =\ /";
    };
    settings = {
      user.name = lib.mkDefault "TobMoeller";
      user.email = lib.mkDefault "tobiasmoellerw@t-online.de";

      push.autoSetupRemote = true;
      init.defaultBranch = "main";
    };
    ignores = [
      "_ide_*"
      ".phpstorm*"
    ];
  };

  # programs.direnv = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   nix-direnv.enable = true;
  # };

  programs.ripgrep = {
    enable = true;
  };

  programs.fzf = {
    enable = true;
  };
}
