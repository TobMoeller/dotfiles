{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Existing installation baseline. Keep its hostname and Plasma for now.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  services.xserver = {
    enable = true;
    xkb.layout = "de";
    xkb.variant = "";
  };
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  console.keyMap = "de";
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.tobias = {
    isNormalUser = true;
    description = "tobias";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = [ pkgs.kdePackages.kate ];
  };
  programs.firefox.enable = true;
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    vim
    enpass
    git
    nodejs
  ];

  # Compatibility baseline, not the package release or an update switch.
  system.stateVersion = "26.05";
}
