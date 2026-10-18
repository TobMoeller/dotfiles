{ self, ... }:
{
  # Shared personal environment. The host supplies the local account details.
  flake.modules.homeManager.tobias = { config, ... }: {
    imports = [
      self.modules.homeManager.dotfiles
      self.modules.homeManager.herdr
      self.modules.homeManager.npm
    ];

    home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

    programs.bash = {
      enable = true;
      # GUI terminals usually start non-login shells, which do not read .profile.
      bashrcExtra = ''
        . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"
      '';
    };
  };
}
