{
  flake.modules.nixos.zsh = {
    programs.zsh.enable = true;
  };

  flake.modules.homeManager.zsh = { config, pkgs, ... }: {
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
        source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
        source "${config.xdg.configHome}/zsh/config.zsh"
      '';
    };

    xdg.configFile."zsh/config.zsh".source = config.lib.file.mkOutOfStoreSymlink
      "${config.dotfiles.repositoryPath}/modules/features/zsh/config.zsh";
    xdg.configFile."zsh/p10k.zsh".source = config.lib.file.mkOutOfStoreSymlink
      "${config.dotfiles.repositoryPath}/modules/features/zsh/p10k.zsh";
  };
}
