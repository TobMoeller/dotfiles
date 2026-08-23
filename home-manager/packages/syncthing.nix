{ config, pkgs, lib, ... }:

# Syncthing — P2P-Ordnersync zwischen Firmenrechner und MacBook. Host-spezifisch
# importiert statt über commons.nix: nur diese beiden Geräte sind Teil der Kette.
# Ohne Dauerläufer darin gilt, dass nur abgeglichen wird, was gleichzeitig läuft.
#
# Bedient wird alles über die Web-GUI auf http://127.0.0.1:8384 — die steckt im
# Binary, ein separates GUI-Paket gibt es nicht.
#
# macOS bleibt hier bewusst außen vor: der Homebrew-Cask bringt eine
# Menüleisten-App mit eigenem Binary mit, und zwei Daemons auf einem
# Config-Verzeichnis vertragen sich nicht. Dort stattdessen:
#   brew install --cask syncthing-app
{
  services.syncthing = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;

    # Geräte und Ordner bleiben in der GUI. Solange `settings` leer ist, legt
    # home-manager den syncthing-init-Service nicht an und rührt die
    # Konfiguration nicht an.
    #
    # ACHTUNG, falls das mal deklarativ werden soll: sobald `settings` etwas
    # enthält — oder `guiCredentials`/`guiAddress` gesetzt sind — läuft der
    # Init-Service, und overrideDevices/overrideFolders (Default true) löschen
    # alles, was nicht hier steht. Ein einzelner settings-Eintrag ohne
    # devices/folders leert damit die gesamte GUI-Konfiguration.
    #
    #   settings.devices."mbp-tm".id = "XXXXXXX-...";
    #   settings.folders."brain" = {
    #     path = "${config.home.homeDirectory}/code/knowledge/brain";
    #     devices = [ "mbp-tm" ];
    #     ignorePatterns = [ ".git" ".obsidian" ".stversions" ];
    #     versioning = { type = "staggered"; params.maxAge = "2592000"; };
    #   };
  };
}
