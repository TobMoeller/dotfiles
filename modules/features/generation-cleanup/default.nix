{
  flake.modules.nixos.generation-cleanup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      command = pkgs.writeShellApplication {
        name = "nixos-generations";
        runtimeInputs = [
          pkgs.python3
          config.nix.package
        ];
        text = ''exec python3 ${./cleanup.py} "$@"'';
      };
    in
    {
      assertions = [
        {
          assertion =
            config.boot.loader.systemd-boot.enable
            && config.boot.loader.systemd-boot.configurationLimit == null;
          message = "Generation cleanup requires systemd-boot without a separate generation limit.";
        }
        {
          assertion = !config.nix.gc.automatic;
          message = "Use generation cleanup's timer instead of a second automatic Nix GC policy.";
        }
      ];

      # Every retained generation should remain available in the boot menu.
      boot.loader.systemd-boot.configurationLimit = lib.mkDefault null;
      environment.systemPackages = [ command ];

      systemd.services.nixos-generation-cleanup = {
        description = "Thin NixOS generations and collect unused store paths";
        unitConfig.ConditionPathExists = "/nix/var/nix/gcroots/dotfiles-known-good";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${command}/bin/nixos-generations apply";
          TimeoutStartSec = "infinity";
          Nice = 19;
          IOSchedulingClass = "idle";
        };
        restartIfChanged = false;
      };
      systemd.timers.nixos-generation-cleanup = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          RandomizedDelaySec = "1h";
          Persistent = true;
        };
      };
    };

  perSystem = { pkgs, ... }: {
    checks.generation-cleanup =
      pkgs.runCommand "generation-cleanup-tests"
        {
          nativeBuildInputs = [ pkgs.python3 ];
        }
        ''
          cp ${./cleanup.py} cleanup.py
          cp ${./test_cleanup.py} test_cleanup.py
          python3 -m unittest -v
          touch "$out"
        '';
  };
}
