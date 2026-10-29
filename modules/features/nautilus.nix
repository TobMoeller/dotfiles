{
  flake.modules.nixos.nautilus = {
    services.gvfs.enable = true;
  };

  flake.modules.homeManager.nautilus = { pkgs, ... }: {
    home.packages = [ pkgs.nautilus ];
  };
}
