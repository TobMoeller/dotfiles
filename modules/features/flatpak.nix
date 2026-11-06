{
  # Flatpak for desktop apps that move faster than nixpkgs or ship
  # proprietary plugins. Apps are installed imperatively and are not part of
  # NixOS generations; see docs/flatpak.md.
  flake.modules.nixos.flatpak = { pkgs, ... }: {
    services.flatpak.enable = true;

    systemd.services.flatpak-flathub = {
      description = "Add the Flathub remote for system-wide Flatpak";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [ pkgs.flatpak ];
      serviceConfig.Type = "oneshot";
      script = ''
        flatpak remote-add --system --if-not-exists flathub \
          https://dl.flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
