{ config, lib, ... }:
{
  options.dotfiles.repoRoot = lib.mkOption {
    type = lib.types.strMatching "/.+";
    description = "Absolute, durable live checkout path (a string, never a Nix store source path).";
  };
  config.home.sessionVariables.DOTFILES = config.dotfiles.repoRoot;
  config.xdg.configFile."dotfiles/session.zsh".text = ''
    export DOTFILES=${lib.escapeShellArg config.dotfiles.repoRoot}
  '';
}
