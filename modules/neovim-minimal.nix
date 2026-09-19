{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    (neovim.override { vimAlias = true; viAlias = true; })
    git curl unzip gnutar gzip nodejs python3
  ];
  xdg.dataFile."nvim/site/lazy.nvim".source = pkgs.vimPlugins.lazy-nvim;
  home.sessionVariables = { EDITOR = "nvim"; VISUAL = "nvim"; };
  xdg.configFile."nvim/init.lua".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/nvim/init.lua";
  xdg.configFile."nvim/lua/config".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/nvim/lua/config";
}
