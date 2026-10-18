{ config, pkgs, nixgl, ... }:

let
  # This machine is a Ryzen APU (AMD Phoenix3, amdgpu/Mesa). nixGLIntel is
  # nixGL's Mesa wrapper and covers Intel *and* AMD — no driver-version pinning
  # (that pain is NVIDIA-only). It provides the OpenGL stack that a nixpkgs GUI
  # app needs on Ubuntu, where the system drivers live outside the nix store.
  nixGL = nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLIntel;

  # Terminal-launchable `ghostty` that runs under nixGL. NOTE: this wraps the
  # CLI only; the GNOME app-grid .desktop entry is not wrapped. If you want to
  # launch Ghostty from the GNOME dash, ask and I'll switch to a fuller wrap
  # that also patches the desktop entry.
  ghostty-nixgl = pkgs.writeShellScriptBin "ghostty" ''
    exec ${nixGL}/bin/nixGLIntel ${pkgs.ghostty}/bin/ghostty "$@"
  '';
in

{
  home.username = "tobias";
  home.homeDirectory = "/home/tobias";

  home.stateVersion = "23.11";

  imports = [
    ./packages/commons.nix
    ./packages/ghostty.nix
    ./packages/syncthing.nix
  ];

  # Shared skills plus red-specific ones; red overrides common on a name clash.
  claudeSkillGroups = [ "common" "red" ];
  claudeAgentGroups = [ "common" "red" ];

  # The team's skills we actually use, linked by name from the shared
  # ai-tooling checkout so every session (and the /work worker) can invoke
  # them directly: the three ticket skills and the in-app docs skill. They are
  # self-contained (shared sections inlined by the team's convention) and write
  # nothing under ai-tooling's tickets/ folder. The rest of ai-tooling (its
  # implementation track, specification, QA, UX, git helpers) is replaced by
  # our pipeline or not part of our flow; /tickets lists what is linked.
  claudeExternalSkills =
    let ai = "${config.home.homeDirectory}/code/RED-telematik-manager/ai-tooling/.claude/skills"; in {
      "feature-story-erstellen" = "${ai}/feature-story-erstellen";
      "bug-ticket-erstellen" = "${ai}/bug-ticket-erstellen";
      "epic-erstellen" = "${ai}/epic-erstellen";
      "feature-doku-pflegen" = "${ai}/feature-doku-pflegen";
    };

  # Read-only devtools-mcp permissions (Jira/Gitea/Confluence/TeamCity) merged
  # into ~/.claude/settings.json on this host only. Modifying tools still prompt.
  claudePermissionGroups = [ "red" ];

  home.packages = with pkgs; [
    ghostty-nixgl   # nixpkgs Ghostty wrapped with nixGL (see let block above)
    # podman # requires uidmap on ubuntu
    # podman-compose
    # slirp4netns # required for podman networking

    # chromium
    # ghostscript
    openfortivpn
    ffmpeg
    tuicr
  ];

  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
    ".ideavimrc".source = ./packages/config/ideavimrc;
  };

  # GNOME app-search launcher for Ghostty. NOTE: `xdg.desktopEntries` installs
  # into the nix profile (~/.nix-profile/share/applications), which GNOME on
  # non-NixOS Ubuntu does NOT scan — so we write the .desktop straight into
  # ~/.local/share/applications, which GNOME always scans. Exec points at the
  # nixGL-wrapped binary and the icon at an absolute store path (both refreshed
  # on every switch); no DBusActivatable, so it launches through the wrapper.
  home.file.".local/share/applications/ghostty.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Name=Ghostty
    Type=Application
    Comment=A terminal emulator
    TryExec=${ghostty-nixgl}/bin/ghostty
    Exec=${ghostty-nixgl}/bin/ghostty --gtk-single-instance=true
    Icon=${pkgs.ghostty}/share/icons/hicolor/512x512/apps/com.mitchellh.ghostty.png
    Categories=System;TerminalEmulator;
    Keywords=terminal;tty;pty;
    StartupNotify=true
    StartupWMClass=com.mitchellh.ghostty
    Terminal=false
  '';

  home.sessionPath = [
    "$HOME/.local/share/JetBrains/Toolbox/scripts"
  ];

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.home-manager.enable = true;

  programs.git.settings = {
    user.name = "TobiasRedMed";
    user.email = "tobias.moeller@redmedical.de";
    pull.rebase = true; # TODO check variable name
    commit.gpgsign = true;

    # SSH signing
    gpg.format = "ssh";
    user.signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
    gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
  };
}
