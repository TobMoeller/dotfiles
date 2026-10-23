{
  flake.modules.nixos.syncthing = {
    networking.firewall = {
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [
        22000
        21027
      ];
    };
  };

  flake.modules.homeManager.syncthing = { pkgs, ... }: {
    services.syncthing = {
      enable = true;
      guiAddress = "127.0.0.1:8384";
      # Pair devices and select folders interactively; preserve GUI changes.
      overrideDevices = false;
      overrideFolders = false;
    };

    home.packages = [ pkgs.syncthing ];
  };
}
