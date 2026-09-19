{ pkgs, ... }:
{
  home.packages = with pkgs; [ fd fzf jq curl hyperfine ripgrep codex ];
  home.sessionPath = [ "$HOME/.local/bin" ];
}
