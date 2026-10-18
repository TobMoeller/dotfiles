{
  flake.modules.nixos.zsh = {
    programs.zsh.enable = true;
  };

  flake.modules.homeManager.zsh = { config, ... }: {
    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        ignoreSpace = true;
        share = true;
      };
      initContent = ''
        source "${config.xdg.configHome}/zsh/config.zsh"
      '';
    };

    xdg.configFile."zsh/config.zsh".source = config.lib.file.mkOutOfStoreSymlink
      "${config.dotfiles.repositoryPath}/modules/features/zsh/config.zsh";
  };
}
