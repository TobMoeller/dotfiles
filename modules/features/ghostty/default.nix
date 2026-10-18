{
  flake.modules.homeManager.ghostty = { config, pkgs, ... }: {
    programs.ghostty.enable = true;
    home.packages = [ pkgs.meslo-lgs-nf ];
    fonts.fontconfig.enable = true;
    home.sessionVariables.TERMINAL = "ghostty";

    xdg.configFile."ghostty/config".source = config.lib.file.mkOutOfStoreSymlink
      "${config.dotfiles.repositoryPath}/modules/features/ghostty/config";
    xdg.configFile."xdg-terminals.list".text = ''
      com.mitchellh.ghostty.desktop
    '';
  };
}
