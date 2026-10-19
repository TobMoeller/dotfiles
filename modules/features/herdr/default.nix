{ inputs, ... }:
{
  flake.modules.homeManager.herdr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      herdr = inputs.nixpkgs-tools.legacyPackages.${pkgs.stdenv.hostPlatform.system}.herdr;
      repository = config.dotfiles.repositoryPath;
    in
    {
      home.packages = [
        herdr
        pkgs.fzf
        pkgs.jq
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.wl-clipboard ];
      xdg.configFile."herdr/config.toml".source =
        config.lib.file.mkOutOfStoreSymlink "${repository}/modules/features/herdr/config.toml";

      home.file.".local/bin/t".source = config.lib.file.mkOutOfStoreSymlink "${repository}/scripts/t";
      home.file.".local/bin/wt".source = config.lib.file.mkOutOfStoreSymlink "${repository}/scripts/wt";

      # Link only our local plugin; preserve other registrations and settings.
      home.activation.herdrVimNav = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${herdr}/bin/herdr plugin link \
          ${lib.escapeShellArg "${repository}/modules/features/herdr/plugins/vim-nav"} --enabled
      '';
    };
}
