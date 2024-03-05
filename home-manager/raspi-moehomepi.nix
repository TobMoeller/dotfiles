{ config, pkgs, lib, ... }:

{
  home.username = "moehomepi";
  home.homeDirectory = "/home/moehomepi";

  home.stateVersion = "23.05";

  imports = [
    ./packages/tmux.nix
    ./packages/zsh.nix
  ];

  home.packages = with pkgs; [
    (php82.buildEnv {
      extensions = ({ enabled, all }: enabled ++ (with all; [
        redis
      ]));
      extraConfig = ''
        memory_limit = 500M
      '';
    })
    php82Packages.composer
    # nodejs_20
    python3
  ];

  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
  };

  home.sessionPath = [
    # "/snap/bin"
  ];

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "TobMoeller";
    userEmail = "tobiasmoellerw@t-online.de";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraLuaConfig = lib.fileContents ./packages/config/neovim/config.lua;
  };
}
