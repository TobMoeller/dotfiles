{ config, pkgs, lib, ... }:
{
  home.packages = [ pkgs.herdr pkgs.jq pkgs.bash ];
  # Link only this file: Herdr also writes mutable files in its config directory.
  xdg.configFile."herdr/config.toml".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/herdr/config.toml";
  home.activation.herdrVimNavigation = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.herdr}/bin/herdr plugin link ${lib.escapeShellArg "${config.dotfiles.repoRoot}/config/herdr/plugins/vim-nav"}
  '';
}
