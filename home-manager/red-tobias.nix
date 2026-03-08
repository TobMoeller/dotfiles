{ config, pkgs, ... }:

{
  home.username = "tobias";
  home.homeDirectory = "/home/tobias";

  home.stateVersion = "23.11";

  imports = [
    ./packages/commons.nix
  ];

  home.packages = with pkgs; [
    # ghostty
    # podman # requires uidmap on ubuntu
    # podman-compose
    # slirp4netns # required for podman networking

    # chromium
    # ghostscript
    openfortivpn
  ];

  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
    ".ideavimrc".source = ./packages/config/ideavimrc;
  };

  home.sessionPath = [
    # "/snap/bin"
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
