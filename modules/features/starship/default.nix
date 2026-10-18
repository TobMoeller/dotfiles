{
  flake.modules.homeManager.starship = { config, ... }: {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = false;
    };

    xdg.configFile."starship.toml".source = config.lib.file.mkOutOfStoreSymlink
      "${config.dotfiles.repositoryPath}/modules/features/starship/starship.toml";
  };
}
