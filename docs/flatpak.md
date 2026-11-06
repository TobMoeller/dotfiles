# Flatpak und Bambu Studio

Das NixOS-Feature `flatpak` aktiviert Flatpak systemweit und legt beim Start
die Quelle Flathub an (Dienst `flatpak-flathub`). Flatpak ist für
Desktop-Programme gedacht, die nixpkgs zu langsam nachzieht oder die
proprietäre Zusätze nachladen. Alles andere kommt weiterhin aus Nix.

Unterschiede zu Nix-Paketen:

- Flatpak-Programme gehören nicht zu den NixOS-Generationen. Ein Rollback
  oder `dotfiles-rebuild` ändert sie nicht.
- Installation und Updates laufen über `flatpak`, nicht über den Flake.
- Programme laufen in einer Sandbox; Dateizugriffe gehen über die
  Desktop-Portale von niri bzw. Plasma.

## Bambu Studio

Die Version in nixpkgs (02.05 im aktuellen Pin) hinkt Upstream deutlich
hinterher; Flathub ist der übliche Weg unter Linux. Nach `dotfiles-rebuild`:

```bash
flatpak install flathub com.bambulab.BambuStudio
flatpak run com.bambulab.BambuStudio   # oder über den App-Launcher
```

Ein neu installiertes Programm erscheint im Launcher eventuell erst nach dem
nächsten Anmelden. Beim ersten Login lädt Bambu Studio das proprietäre
Netzwerk-Plugin für Cloud- und LAN-Druck nach.

Die Firewall bleibt bewusst zu. Cloud-Druck über den Bambu-Account braucht
nur ausgehende Verbindungen. Die automatische Druckersuche im LAN-Modus
funktioniert dagegen nicht: Bambu-Drucker melden sich per SSDP an UDP 2021.
Falls sie später nötig ist, nur für die Dauer der Suche öffnen, statt den
Port dauerhaft freizugeben:

```bash
sudo nixos-firewall-tool open udp 2021   # bis zum nächsten Neustart/Rebuild
sudo nixos-firewall-tool reset
```

Updates und Entfernen:

```bash
flatpak update
flatpak uninstall com.bambulab.BambuStudio
flatpak uninstall --unused
```

Bambu Suite (Laser/Schneidplotter) gibt es nur für Windows und macOS.
OrcaSlicer (Fork von Bambu Studio) liegt in nixpkgs und wäre die
deklarative Alternative.
