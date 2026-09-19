{
  description = "SSH-first personal tools for devbox-01";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      home = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./hosts/devbox-01/home.nix ];
      };
    in {
      homeConfigurations."tobias@devbox-01" = home;
      apps.${system}.home-manager = {
        type = "app";
        meta.description = "Home Manager CLI pinned by this flake";
        program = "${home.config.programs.home-manager.package}/bin/home-manager";
      };
    };
}
