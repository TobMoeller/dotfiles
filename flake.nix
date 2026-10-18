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
        ./modules/features/herdr/default.nix
        ./modules/features/nvidia-prime.nix
        ./modules/features/npm.nix
        ./modules/features/hibernate.nix
        ./modules/features/plasma-sleep/default.nix
        ./modules/users/tobias.nix
        ./modules/hosts/thinkpad.nix
      ];

      systems = [ "x86_64-linux" ];
      perSystem = { pkgs, ... }: {
        formatter = pkgs.nixfmt;
      };
    };
}
