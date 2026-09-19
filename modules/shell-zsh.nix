{ config, pkgs, ... }:
{
  home.packages = with pkgs; [ zsh zsh-completions ];
  xdg.dataFile."zsh/plugins/powerlevel10k".source = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
  xdg.dataFile."zsh/plugins/autosuggestions".source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
  xdg.dataFile."zsh/plugins/syntax-highlighting".source = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting";
  xdg.configFile."zsh/p10k.zsh".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/zsh/p10k.zsh";
  home.file.".zshenv".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/zsh/zshenv";
  home.file.".zshrc".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/zsh/zshrc";
}
