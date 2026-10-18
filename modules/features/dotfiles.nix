{
  flake.modules.homeManager.dotfiles = { config, lib, ... }: {
    options.dotfiles.repositoryPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/code/tobmoeller/dotfiles";
      description = "Absolute checkout path used for directly editable configuration files.";
    };

    config.home.sessionVariables.DOTFILES = config.dotfiles.repositoryPath;
  };
}
