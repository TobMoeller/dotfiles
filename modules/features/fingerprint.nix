{
  flake.modules.nixos.fingerprint = { config, lib, ... }: {
    services.fprintd.enable = true;

    # Noctalia v5 verifies fingers directly through fprintd over D-Bus.
    # Its password path uses PAM login and must not wait for the same reader.
    security.pam.services =
      lib.genAttrs
        [
          "login"
          "sudo"
          "sudo-i"
          "su"
          "su-l"
          "sshd"
          "polkit-1"
        ]
        (_: {
          fprintAuth = false;
        })
      // {
        # SDDM normally delegates to login; give only its greeter a finger step.
        sddm.rules.auth.fprintd = lib.mkIf config.services.displayManager.sddm.enable {
          order = config.security.pam.services.sddm.rules.auth.login.order - 10;
          control = "sufficient";
          modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
          settings = {
            timeout = 5;
            max-tries = 1;
          };
        };
      };
  };
}
