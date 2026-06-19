{ config, pkgs, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/code/tobmoeller/dotfiles";
  php = pkgs.php85.buildEnv {
    extensions = ({ enabled, all}: enabled ++ (with all; [
      redis
      gnupg
      yaml
      xdebug
      # imagick
      # pcov
      # rdkafka
      # mongodb
    ]));
    extraConfig = ''
      memory_limit = 500M
      xdebug.mode=coverage
    '';
  };
in {
  imports = [
    ./tmux.nix
    ./zsh.nix
    ./nvim.nix
  ];

  # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "intelephense"
    # "ngrok"
    "vim-visual-star-search"
    "vim-highlightedyank"
  ];

  home.packages = with pkgs; [
    hyperfine
    meslo-lgs-nf # nerd font for powerlevel10k theme
    # timewarrior
    jq # command line json processor
    # minikube

    php
    php.packages.composer

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
  ];

  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
    ".npmrc".text = "prefix=${config.home.homeDirectory}/.npm-global";

    ".local/bin/t".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home-manager/packages/scripts/t";
    ".local/bin/wt".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home-manager/packages/scripts/wt";

    ".claude/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home-manager/packages/config/claude/skills";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
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
    settings = {
      alias = {
        s = "status -sb";
        st = "status";
        ci = "commit";
        co = "checkout";
        nah = "!git reset --hard && git clean -df";
        alias = "! git config --get-regexp ^alias\. | sed -e s/^alias\.// -e s/\ /\ =\ /";
      };
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
