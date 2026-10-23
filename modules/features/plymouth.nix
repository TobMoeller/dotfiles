{
  flake.modules.nixos.plymouth = {
    boot.plymouth = {
      enable = true;
      theme = "bgrt";
    };
    # Make the configured console keyboard layout available before LUKS unlock.
    console.earlySetup = true;
  };
}
