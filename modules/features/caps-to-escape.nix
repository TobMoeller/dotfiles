{
  flake.modules.nixos.caps-to-escape = {
    # Remap below the desktop: applies in niri, Plasma and virtual consoles.
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings.main.capslock = "esc";
      };
    };
  };
}
