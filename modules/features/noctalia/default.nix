{ inputs, ... }:
{
  flake.modules.nixos.noctalia = {
    hardware.bluetooth.enable = true;
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
    xdg.sounds.enable = true;
  };

  flake.modules.homeManager.noctalia = { config, pkgs, ... }: {
    # v5 is available in the existing pinned tools input; stable has v4.
    home.packages = [
      inputs.nixpkgs-tools.legacyPackages.${pkgs.stdenv.hostPlatform.system}.noctalia
    ];
    xdg.configFile."noctalia/config.toml".source = config.lib.file.mkOutOfStoreSymlink
      "${config.dotfiles.repositoryPath}/modules/features/noctalia/config.toml";
  };
}
