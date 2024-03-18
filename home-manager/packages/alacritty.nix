{ config, pkgs, ... }:

{
  xdg.configFile."alacritty/alacritty.toml".source = ./config/alacritty/alacritty.toml;
  xdg.configFile."alacritty/catppuccin-mocha.toml".source = ./config/alacritty/catppuccin-mocha.toml;

  # wip: this does not work for single files... maybe work on different method to implement
  # xdg.configFile."alacritty/catppuccin-mocha.toml".source = builtins.fetchGit {
  #   url = "https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml";
  #   rev = "071d73effddac392d5b9b8cd5b4b527a6cf289f9";
  # };
}
