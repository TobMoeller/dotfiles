{
  flake.modules.nixos.docker = { pkgs, ... }: {
    virtualisation.docker = {
      enable = true;
      # First CLI use starts Docker; it stays running until stopped.
      enableOnBoot = false;
      autoPrune.enable = false;
      daemon.settings = {
        "log-driver" = "local";
        "log-opts" = {
          "max-size" = "10m";
          "max-file" = "3";
        };
        # Default bridge and new Compose networks: publish locally by default.
        # Projects can explicitly use 0.0.0.0 for LAN demos.
        ip = "127.0.0.1";
        "default-network-opts".bridge = {
          "com.docker.network.bridge.host_binding_ipv4" = "127.0.0.1";
        };
      };
    };
    # The Docker package already includes Compose and Buildx plugins.
    environment.systemPackages = [ pkgs.lazydocker ];
  };
}
