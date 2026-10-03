{ nixgl, ... }:
{
  imports = [
    ../../modules/repository.nix
    ../../modules/brain.nix
    ../../modules/cli-core.nix
    ../../modules/shell-zsh.nix
    ../../modules/git.nix
    ../../modules/neovim.nix
    ../../modules/herdr.nix
    ../../modules/tmux.nix
    ../../modules/ghostty.nix
  ];

  dotfiles.repoRoot = "/home/tobias/code/tobmoeller/dotfiles";
  dotfiles.brain.enable = true;
  targets.genericLinux.nixGL.packages = nixgl.packages;
  targets.genericLinux.nixGL.defaultWrapper = "mesa";
  home.username = "tobias";
  home.homeDirectory = "/home/tobias";
  home.stateVersion = "26.05";
  xdg.enable = true;
  xdg.mime.enable = false;
  systemd.user.enable = false;
  programs.home-manager.enable = true;
}
