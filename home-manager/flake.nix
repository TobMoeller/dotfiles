{
  description = "Home Manager configuration of tobiasmoeller";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      pkgs = nixpkgs.legacyPackages;
    in {
      defaultPackage = {
        aarch64-darwin = home-manager.defaultPackage.aarch64-darwin;
        x86_64-linux = home-manager.defaultPackage.x86_64-linux;
        aarch64-linux = home-manager.defaultPackage.aarch64-linux;
      };

      homeConfigurations = {
        "tobiasmoeller@mbp-tm" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs.aarch64-darwin;

          modules = [ ./mbp-tobiasmoeller.nix ];

          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };

        "tmoeller@EPNB83" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs.x86_64-linux;

          modules = [ ./ep-wsl-tmoeller.nix ];
        };

        "moehomepi@moehomepi" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs.aarch64-linux;

          modules = [ ./raspi-moehomepi.nix ];
        };
      };
    };
}
