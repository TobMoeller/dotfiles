{
  flake.modules.nixos.nvidia-prime = { lib, pkgs, ... }: {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.nvidia = {
      # NVIDIA's open kernel modules, with the matching NVIDIA userspace driver.
      open = true;
      branch = "stable";
      modesetting.enable = true;

      prime.offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      powerManagement = {
        enable = true;
        finegrained = lib.mkDefault true;
      };

      # Save VRAM on the encrypted disk, rather than a potentially small tmpfs.
      moduleParams.nvidia.NVreg_TemporaryFilePath = "/var/lib/nvidia-sleep";
    };

    systemd.tmpfiles.rules = [ "d /var/lib/nvidia-sleep 0700 root root -" ];

    # Tools for checking the driver, render offload and Vulkan after reboot.
    environment.systemPackages = with pkgs; [
      pciutils
      mesa-demos
      vulkan-tools
    ];
  };
}
