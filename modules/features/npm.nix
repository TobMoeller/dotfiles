{
  flake.modules.homeManager.npm = { config, ... }: {
    # npm puts global commands in <prefix>/bin and packages in <prefix>/lib.
    home.sessionVariables.NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.local";
  };
}
