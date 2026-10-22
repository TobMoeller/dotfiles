{ self, ... }:
{
  # Shared personal environment. The host supplies the local account details.
  flake.modules.homeManager.tobias = { config, ... }: {
    imports = [
      self.modules.homeManager.dotfiles
      self.modules.homeManager.development
      self.modules.homeManager.herdr
      self.modules.homeManager.neovim
      self.modules.homeManager.npm
      self.modules.homeManager.zsh
      self.modules.homeManager.starship
      self.modules.homeManager.git
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
