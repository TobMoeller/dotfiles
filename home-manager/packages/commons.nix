{ config, pkgs, lib, ... }:

let
  # node2nix to install custom npm packages, tho it does not work for volar as not all sub dependencies get linked
  # TODO remove custom npm packages once all volar dependencies get resolved as nix packages
  # extraNodePackages = import ./node/default.nix {
  #   inherit pkgs;
  #   nodejs = pkgs.nodejs_20;
  # };
  nodejs = pkgs.nodejs_20;
in {
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

    # nodejs_20
    nodejs
    python3

    # LSP packages
    phpactor
    # typescript
    # vscode-langservers-extracted
    # nodePackages.typescript-language-server
    # extraNodePackages."@vue/language-server"
    # extraNodePackages."@vue/typescript-plugin"
    # nodePackages.volar
    nodePackages.intelephense
    pyright
    nodePackages."@tailwindcss/language-server" # (not found in nix packages: https://github.com/NixOS/nixpkgs/issues/200244)

    (pkgs.writeShellScriptBin "t" (builtins.readFile ./scripts/t))
    (pkgs.writeShellScriptBin "updateExtraNodePackages" "nix-shell -p nodePackages.node2nix --command 'node2nix -i ./node-packages.json -o node-packages.nix'")
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
    # EDITOR = "emacs";
  };

  home.activation = {
    installNpmPackages = ''
      export NPM_CONFIG_PREFIX=${config.home.homeDirectory}/.npm-global
      export PATH=${nodejs}/bin:$PATH

      check_and_install() {
        local package=$1
        local version=$2
        if ! npm list -g --depth=0 | grep -q "''${package}@''${version}"; then
          npm install -g "''${package}@''${version}"
        fi
      }

      check_and_install "typescript" "5.4.5"
      check_and_install "typescript-language-server" "4.3.3"
      check_and_install "@vue/language-server" "2.0.19"
      check_and_install "@vue/typescript-plugin" "2.0.19"
    '';
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
    ignores = [
      "_ide_*"
      ".phpstorm*"
    ];
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
