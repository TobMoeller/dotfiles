{
  flake.modules.homeManager.system-tools = { pkgs, ... }: {
    home.packages = with pkgs; [
      unzip
      zip
    ];
    programs.btop.enable = true;
    programs.fastfetch.enable = true;
  };
}
