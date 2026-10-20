{
  flake.modules.homeManager.voice-chat = { pkgs, ... }: {
    home.packages = [
      pkgs.discord
      pkgs.teamspeak6-client
    ];
  };
}
