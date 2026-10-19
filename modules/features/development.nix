{
  flake.modules.homeManager.development = {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };
  };

  # Tools for working on this repository; project runtimes belong to projects.
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShellNoCC {
      packages = [
        pkgs.nixfmt
        pkgs.shellcheck
      ];
    };
  };

  flake.templates = {
    default = {
      path = ../../templates/devshell;
      description = "Minimal project devShell with optional direnv integration";
    };
  };
}
