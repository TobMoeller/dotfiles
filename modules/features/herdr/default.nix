{ inputs, ... }:
{
  flake.modules.homeManager.herdr = { config, pkgs, ... }: {
    home.packages = [
      inputs.nixpkgs-tools.legacyPackages.${pkgs.stdenv.hostPlatform.system}.herdr
    ];
    xdg.configFile."herdr/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.repositoryPath}/modules/features/herdr/config.toml";
  };
}
