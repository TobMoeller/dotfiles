{ ... }:
{
  imports = [
    ../../modules/repository.nix
    ../../modules/cli-core.nix
    ../../modules/shell-zsh.nix
    ../../modules/git.nix
    ../../modules/neovim-minimal.nix
    ../../modules/herdr.nix
    ../../modules/tmux.nix
  ];

  dotfiles.repoRoot = "/home/tobias/code/tobmoeller/dotfiles";
  home.username = "tobias";
  home.homeDirectory = "/home/tobias";
  home.stateVersion = "26.05";
  xdg.enable = true;
  xdg.mime.enable = false;
  systemd.user.enable = false;
  programs.home-manager.enable = true;
}
