{ inputs, self, ... }:
let
  # Output name and configured hostname share one source of truth.
  hostName = "nixos";
in
{
  flake.modules.nixos.thinkpad = { config, pkgs, ... }: {
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
      self.modules.nixos.nautilus
      self.modules.nixos.flatpak
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

    # NVIDIA's new feature branch (hashes from nixos-unstable): 610.57.04
    # fixed suspend/resume failures with RTD3. Drop this block once the
    # system default reaches 610+; see docs/thinkpad-hardware.md.
    hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "615.78.08";
      sha256_64bit = "sha256-Pj9t3cLudnoIGFMAr3vjyyhuznZpjS3eNSRZl4LQf/4=";
      sha256_aarch64 = "sha256-UHYBE1AYHoGgMfD9AS/jX+S+N8eCDWUft6qolK9Eejc=";
      openSha256 = "sha256-HBINiOjL0ZJLIAJeNIBYHBnwgUXtNwPPtnFpAI1YwF4=";
      settingsSha256 = "sha256-inDRpG02sdDgHmlqgu/DsgK8OFdOt1fZIYyXdhlGC/c=";
      persistencedSha256 = "sha256-RzeR6Ldct6MUxjnXRyThdh5Y3jjMehTVg85MtwuWNX4=";
    };

    # With 595.71.05, both suspend paths hit a GSP crash with fine-grained
    # RTD3 (Xid 120); coarse-grained (finegrained = false plus
    # NVreg_DynamicPowerManagement = "0x01") passed suspend and hibernate.
    # With 615.78.08, fine-grained (feature default) passed both as well.
    # If Xid 120 returns, restore those two settings.

    # Second login session that renders niri on NVIDIA (see docs/niri.md).
    services.displayManager.sessionPackages =
      let
        launcher = pkgs.writeShellScript "niri-nvidia-session" ''
          export NIRI_CONFIG="$HOME/.config/niri/nvidia.kdl"
          ${config.programs.niri.package}/bin/niri-session "$@"
          status=$?
          # niri-session imports the login environment into systemd --user;
          # drop the override so a later normal session renders on Intel again.
          systemctl --user unset-environment NIRI_CONFIG
          exit $status
        '';
      in
      [
        ((pkgs.writeTextDir "share/wayland-sessions/niri-nvidia.desktop" ''
          [Desktop Entry]
          Name=Niri (NVIDIA)
          Comment=Niri rendered on the NVIDIA GPU, for the dock monitors
          Exec=${launcher}
          Type=Application
          DesktopNames=niri
        '').overrideAttrs { passthru.providedSessions = [ "niri-nvidia" ]; })
      ];

    # CPU and GPU share one cooler; CPU turbo costs the GPU thermal headroom.
    # GameMode disables turbo while a game runs (see docs/gaming.md).
    systemd.tmpfiles.rules = [
      "z /sys/devices/system/cpu/intel_pstate/no_turbo 0664 root gamemode -"
    ];
    programs.gamemode.settings.custom = {
      start = toString (pkgs.writeShellScript "gamemode-turbo-off" ''
        echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
      '');
      end = toString (pkgs.writeShellScript "gamemode-turbo-on" ''
        echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo
      '');
    };

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
          self.modules.homeManager.nautilus
          self.modules.homeManager.noctalia
          self.modules.homeManager.ghostty
          self.modules.homeManager.chrome
          self.modules.homeManager.thunderbird
          self.modules.homeManager.vlc
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
        services.ollama.package =
          let
            toolsPkgs = import inputs.nixpkgs-tools {
              system = pkgs.stdenv.hostPlatform.system;
              config.allowUnfree = true;
            };
          in
          toolsPkgs.ollama-cuda.override {
            cudaArches = [ "sm_86" ];
            # Keep CUDA 12.9, with all build hooks from the same package set.
            cudaPackages = toolsPkgs.cudaPackages_12;
          };
        programs.btop.package = pkgs.btop.override { cudaSupport = true; };
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
        xdg.configFile."niri/nvidia.kdl".source =
          config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.repositoryPath}/hosts/thinkpad/niri-nvidia.kdl";
      };
    };
  };

  flake.nixosConfigurations.${hostName} = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.modules.nixos.thinkpad ];
  };
}
