{ inputs, self, ... }:
let
  # Output name and configured hostname share one source of truth.
  hostName = "nixos";
in
{
  flake.modules.nixos.thinkpad = { pkgs, ... }: {
    networking.hostName = hostName;
    imports = [
      self.modules.nixos.base
      self.modules.nixos.docker
      self.modules.nixos.syncthing
      self.modules.nixos.generation-cleanup
      self.modules.nixos.nvidia-prime
      self.modules.nixos.hibernate
      self.modules.nixos.plymouth
      self.modules.nixos.fingerprint
      self.modules.nixos.zsh
      self.modules.nixos.niri
      self.modules.nixos.noctalia
      self.modules.nixos.gaming
      self.modules.nixos.airpods
      self.modules.nixos.caps-to-escape
      ../../hosts/thinkpad/configuration.nix
      inputs.home-manager.nixosModules.home-manager
    ];

    users.users.tobias.shell = pkgs.zsh;
    users.users.tobias.extraGroups = [
      "gamemode"
      "docker"
      "librepods"
    ];

    # The internal display is driven by Intel; make it available for Plymouth.
    boot.initrd.kernelModules = [ "i915" ];

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
      users.tobias = { config, pkgs, ... }: {
        imports = [
          self.modules.homeManager.tobias
          self.modules.homeManager.syncthing
          self.modules.homeManager.local-ai
          self.modules.homeManager.plasma-sleep
          self.modules.homeManager.niri
          self.modules.homeManager.noctalia
          self.modules.homeManager.ghostty
          self.modules.homeManager.chrome
          self.modules.homeManager.gaming
          self.modules.homeManager.voice-chat
          self.modules.homeManager.airpods
        ];
        home = {
          username = "tobias";
          homeDirectory = "/home/tobias";
          stateVersion = "26.05";
        };
        # CUDA backends belong to this NVIDIA host, not the shared AI feature.
        services.ollama.package = pkgs.ollama-cuda.override { cudaArches = [ "sm_86" ]; };
        localAI.whisperPackage =
          (pkgs.whisper-cpp.override {
            cudaSupport = true;
            cudaPackages = pkgs.cudaPackages;
          }).overrideAttrs
            (old: {
              # RTX 3080 Laptop: avoid compiling kernels for unrelated GPUs.
              cmakeFlags = old.cmakeFlags ++ [ "-DCMAKE_CUDA_ARCHITECTURES=86" ];
            });

        # Private identity belongs to this host, not the shared Git feature.
        programs.git.settings.user = {
          name = "TobMoeller";
          email = "tobiasmoellerw@t-online.de";
        };
        home.file.".local/bin/dotfiles-rebuild".source =
          config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.repositoryPath}/scripts/rebuild";
        xdg.configFile."niri/outputs.kdl".source =
          config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.repositoryPath}/hosts/thinkpad/niri-outputs.kdl";
      };
    };
  };

  flake.nixosConfigurations.${hostName} = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.modules.nixos.thinkpad ];
  };
}
