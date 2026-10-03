{ config, pkgs, ... }:
{
  home.packages = with pkgs; [ fd fzf jq curl hyperfine ripgrep nodejs ];
  home.sessionPath = [ "$HOME/.local/bin" "$HOME/.local/share/npm/bin" ];
  home.file.".npmrc".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/npm/npmrc";
}
