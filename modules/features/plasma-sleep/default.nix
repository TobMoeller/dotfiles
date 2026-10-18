{
  flake.modules.homeManager.plasma-sleep = { config, ... }: {
    xdg.configFile."powerdevilrc".source = config.lib.file.mkOutOfStoreSymlink
      "${config.dotfiles.repositoryPath}/modules/features/plasma-sleep/powerdevilrc";
  };
}
