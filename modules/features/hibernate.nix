{
  flake.modules.nixos.hibernate = {
    # systemd discovers the active swapfile and records its device/offset in
    # EFI HibernateLocation. The initrd resumes after unlocking encrypted root.
    boot.initrd.systemd.enable = true;

    # Fallback when no desktop power manager handles the lid (e.g. a TTY).
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchExternalPower = "suspend-then-hibernate";
    };

    systemd.sleep.settings.Sleep = {
      AllowHibernation = true;
      AllowSuspendThenHibernate = true;
      # Only applies when suspend-then-hibernate is explicitly requested.
      HibernateDelaySec = "1h";
      HibernateOnACPower = false;
    };
  };
}
