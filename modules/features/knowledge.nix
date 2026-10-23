{
  flake.modules.homeManager.knowledge =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = [ pkgs.obsidian ];
      home.sessionVariables = {
        BRAIN = lib.mkDefault "${config.home.homeDirectory}/code/knowledge/brain";
        PROJECT_LOG = lib.mkDefault "${config.home.homeDirectory}/code/knowledge/project-log";
        WORK_LOG = lib.mkDefault config.home.sessionVariables.PROJECT_LOG;
      };
      home.file.".local/bin/dotfiles-init-knowledge".source =
        config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.repositoryPath}/scripts/init-knowledge";
    };
}
