{ config, pkgs, ... }:
{
  home.packages = [ pkgs.git ];
  xdg.configFile."git/config".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/git/config";
  xdg.configFile."git/ignore".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/git/ignore";
}
