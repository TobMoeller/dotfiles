{ lib, ... }:
{
  options.dotfiles.repoRoot = lib.mkOption {
    type = lib.types.strMatching "/.+";
    description = "Absolute, durable live checkout path (a string, never a Nix store source path).";
  };
}
