{ inputs, self, ... }:
let
  # Output name and configured hostname share one source of truth.
  hostName = "nixos";
in
{
  flake.modules.nixos.thinkpad = {
    networking.hostName = hostName;
    imports = [
      self.modules.nixos.base
      self.modules.nixos.nvidia-prime
      self.modules.nixos.hibernate
      ../../hosts/thinkpad/configuration.nix
      inputs.home-manager.nixosModules.home-manager
    ];

    # Measured PCI addresses on this ThinkPad; PRIME uses decimal notation.
    hardware.nvidia.prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # Both suspend paths hit a GSP crash with fine-grained RTD3 (Xid 120).
    # Coarse-grained runtime PM passed suspend and hibernate on this device.
    hardware.nvidia.powerManagement.finegrained = false;
    hardware.nvidia.moduleParams.nvidia.NVreg_DynamicPowerManagement = "0x01";

    # ext4 inside LUKS: the hibernation image is encrypted along with root.
    swapDevices = [
      {
        device = "/swapfile";
        size = 80 * 1024; # MiB: 80 GiB for 64 GiB RAM plus headroom.
      }
    ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.tobias = { config, ... }: {
        imports = [
          self.modules.homeManager.tobias
          self.modules.homeManager.plasma-sleep
        ];
        home = {
          username = "tobias";
          homeDirectory = "/home/tobias";
          stateVersion = "26.05";
        };
        home.file.".local/bin/dotfiles-rebuild".source =
          config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.repositoryPath}/scripts/rebuild";
      };
    };
  };

  flake.nixosConfigurations.${hostName} = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.modules.nixos.thinkpad ];
  };
}
