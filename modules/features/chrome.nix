{
  flake.modules.homeManager.chrome = { pkgs, ... }: {
    home.packages = [ pkgs.google-chrome ];
    home.sessionVariables.BROWSER = "google-chrome-stable";
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = [ "google-chrome.desktop" ];
        "application/xhtml+xml" = [ "google-chrome.desktop" ];
        "x-scheme-handler/http" = [ "google-chrome.desktop" ];
        "x-scheme-handler/https" = [ "google-chrome.desktop" ];
      };
    };
  };
}
