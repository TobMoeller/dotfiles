{
  flake.modules.nixos.airpods = {
    hardware.bluetooth.enable = true;
    programs.librepods.enable = true;

    services.pipewire.wireplumber.extraConfig."51-airpods-avrcp" = {
      "monitor.bluez.properties"."bluez5.dummy-avrcp-player" = true;
    };
  };

  flake.modules.homeManager.airpods = { lib, pkgs, ... }: {
    systemd.user.services.librepods = {
      Unit = {
        Description = "LibrePods AirPods controls";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        # Use NixOS's capability wrapper, including for graphical autostart.
        ExecStart = "/run/wrappers/bin/librepods --hide";
        Environment = "PATH=${lib.makeBinPath [ pkgs.bluez ]}:/run/current-system/sw/bin";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
