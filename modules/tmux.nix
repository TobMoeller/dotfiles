{ config, pkgs, ... }:
{
  home.packages = [ pkgs.tmux ];
  xdg.configFile."tmux/tmux.conf".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/tmux/tmux.conf";
}
