{
  flake.modules.homeManager.vlc = { pkgs, ... }: {
    home.packages = [ pkgs.vlc ];
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "video/mp4" = [ "vlc.desktop" ];
        "video/x-matroska" = [ "vlc.desktop" ];
        "video/webm" = [ "vlc.desktop" ];
        "video/quicktime" = [ "vlc.desktop" ];
        "video/x-msvideo" = [ "vlc.desktop" ];
        "video/x-ms-wmv" = [ "vlc.desktop" ];
        "video/mpeg" = [ "vlc.desktop" ];
        "video/ogg" = [ "vlc.desktop" ];
        "video/x-flv" = [ "vlc.desktop" ];
        "video/mp2t" = [ "vlc.desktop" ];
        "video/3gpp" = [ "vlc.desktop" ];
        "video/3gpp2" = [ "vlc.desktop" ];
      };
    };
  };
}
