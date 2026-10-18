{
  flake.modules.nixos.niri = { pkgs, ... }: {
    programs.niri = {
      enable = true;
      # GTK file chooser; retain the existing KDE file manager.
      useNautilus = false;
    };
    environment.systemPackages = with pkgs; [
      xwayland-satellite
      fuzzel
    ];
  };

  flake.modules.homeManager.niri = { config, ... }: {
    xdg.configFile."niri/config.kdl".source = config.lib.file.mkOutOfStoreSymlink
      "${config.dotfiles.repositoryPath}/modules/features/niri/config.kdl";
  };
}
