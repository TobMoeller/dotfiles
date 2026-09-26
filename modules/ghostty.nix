{ config, lib, pkgs, ... }:
{
  home.packages = [ pkgs.meslo-lgs-nf ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isLinux (config.lib.nixGL.wrap pkgs.ghostty);
  fonts.fontconfig.enable = lib.mkIf pkgs.stdenv.hostPlatform.isLinux true;
  xdg.configFile."ghostty/config".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/ghostty/config";
}
