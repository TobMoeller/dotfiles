{
  flake.modules.nixos.gaming = { pkgs, ... }: {
    programs.steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
      # Make these commands available inside Steam's FHS environment too.
      extraPackages = with pkgs; [ gamemode mangohud gamescope ];
      protontricks.enable = true;
    };
    programs.gamemode.enable = true;
    # Optional nested compositor for individual games; keep the niri session.
    programs.gamescope.enable = true;
  };

  flake.modules.homeManager.gaming = { config, ... }: {
    programs.mangohud.enable = true;
    xdg.configFile."MangoHud/MangoHud.conf".source = config.lib.file.mkOutOfStoreSymlink
      "${config.dotfiles.repositoryPath}/modules/features/gaming/MangoHud.conf";
  };
}
