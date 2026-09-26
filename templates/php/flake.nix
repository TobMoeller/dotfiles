{
  description = "Personal PHP 8.5 and Node.js 24 LTS development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
    in {
      devShells = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          php = pkgs.php85.buildEnv {
            extensions = { enabled, all }: enabled ++ [ all.bcmath all.intl all.pdo_mysql all.zip ];
            extraConfig = ''
              memory_limit = 512M
            '';
          };
        in {
          default = pkgs.mkShell {
            packages = [ php php.packages.composer pkgs.nodejs_24 pkgs.git pkgs.unzip ];
          };
        });
    };
}
