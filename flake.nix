{
  description = "Tobias' systems and personal development environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # herdr is not yet available in the 26.05 package set.
    nixpkgs-tools.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.modules
        ./modules/system/base.nix
        ./modules/features/dotfiles.nix
        ./modules/features/development.nix
        ./modules/features/knowledge.nix
        ./modules/features/local-ai/default.nix
        ./modules/features/syncthing.nix
        ./modules/features/docker.nix
        ./modules/features/generation-cleanup/default.nix
        ./modules/features/herdr/default.nix
        ./modules/features/neovim/default.nix
        ./modules/features/nvidia-prime.nix
        ./modules/features/npm.nix
        ./modules/features/hibernate.nix
        ./modules/features/plymouth.nix
        ./modules/features/fingerprint.nix
        ./modules/features/plasma-sleep/default.nix
        ./modules/features/zsh/default.nix
        ./modules/features/starship/default.nix
        ./modules/features/git.nix
        ./modules/features/niri/default.nix
        ./modules/features/noctalia/default.nix
        ./modules/features/ghostty/default.nix
        ./modules/features/chrome.nix
        ./modules/features/gaming/default.nix
        ./modules/features/voice-chat.nix
        ./modules/features/airpods.nix
        ./modules/features/caps-to-escape.nix
        ./modules/users/tobias.nix
        ./modules/hosts/thinkpad.nix
      ];

      systems = [ "x86_64-linux" ];
      perSystem = { pkgs, ... }: {
        formatter = pkgs.nixfmt;
      };
    };
}
