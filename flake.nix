{
  description = "SSH-first personal tools for devbox-01";

  inputs = {
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          "vim-visual-star-search" "vim-highlightedyank" "intelephense"
        ];
      };
      home = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit nixgl; };
        modules = [ ./hosts/devbox-01/home.nix ];
      };
    in {
      templates.php = {
        path = ./templates/php;
        description = "Personal PHP and Node development environment";
      };
      homeConfigurations."tobias@devbox-01" = home;
      apps.${system}.home-manager = {
        type = "app";
        meta.description = "Home Manager CLI pinned by this flake";
        program = "${home.config.programs.home-manager.package}/bin/home-manager";
      };
    };
}
