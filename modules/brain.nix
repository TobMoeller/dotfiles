{ config, lib, pkgs, ... }:
let
  cfg = config.dotfiles.brain;
in {
  options.dotfiles.brain = {
    enable = lib.mkEnableOption "personal Brain integration";
    path = lib.mkOption {
      type = lib.types.strMatching "/.+";
      default = "${config.home.homeDirectory}/code/knowledge/brain";
      description = "Absolute path of the mutable Brain checkout.";
    };
    syncthing.enable = lib.mkEnableOption "Syncthing CLI for Brain (pairing and service setup are separate)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.git ] ++ lib.optional cfg.syncthing.enable pkgs.syncthing;
    home.sessionVariables.BRAIN = cfg.path;
    xdg.configFile."dotfiles/session.zsh".text = lib.mkAfter ''
      export BRAIN=${lib.escapeShellArg cfg.path}
    '';
  };
}
