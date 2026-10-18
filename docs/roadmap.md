# Nächste Schritte

- [x] Grundgerüst auswerten und Lockfile erzeugen.
- [x] Vollständigen ThinkPad-Systembuild ohne Aktivierung durchführen (2026-10-18).
- [x] Grundkonfiguration aktiviert und mehrfach neu gestartet; vorherige NixOS-Generationen bleiben verfügbar.
- [ ] Hardware erfassen: GPU-IDs, tatsächlich verfügbare VRAM-Größe, externe Monitoranschlüsse, BIOS-Grafikmodus.
- [ ] Vulkan, externe Monitore und später CUDA am Gerät prüfen.
- [x] NVIDIA-Treiber, Intel-/NVIDIA-Offload und Runtime-Suspend nach Neustart geprüft.
- [x] System-Suspend/Resume mit coarse-grained Runtime-PM (0x01) und Standard-Notifier wiederholt getestet: NVIDIA-Offload funktioniert nach dem Aufwachen. Akku-Verbrauch im längeren Schlaf noch nicht abschließend gemessen.
- [x] 80-GiB-Swapdatei im verschlüsselten Root-Dateisystem und Wiederaufnahme beim Boot eingerichtet.
- [x] Hibernate manuell mit erhaltener Sitzung, NVIDIA, Audio und Netzwerk getestet.
- [ ] Suspend-then-Hibernate testen und als Desktop-Schlafaktion einrichten (zunächst nach einer Stunde im Akkubetrieb).
- [x] Zwischencommit einschließlich getesteter Suspend-/Hibernate-Pfade und aktivierter kombinierter Schlafaktion erstellen; Übergangstest bleibt offen.
- [x] SSH-Schlüssel vom Benutzer bei GitHub hinterlegt; `origin` auf `git@github.com:TobMoeller/dotfiles.git` umgestellt.
- [x] SSH-Verbindung zu GitHub erfolgreich authentifiziert (Benutzer).
- [ ] Ersten Push von `nixos-foundation` durchführen (Benutzer; Schlüssel mit Passphrase). Der ursprüngliche Name kollidierte mit dem bestehenden Remote-Branch `rebuild`.
- [x] Gemeinsame Git-Konfiguration und private ThinkPad-Identität deklarieren; Arbeitsidentität folgt beim Arbeitsgerät.
- [x] zsh mit nativer Konfiguration deklarieren und bauen.
- [ ] zsh/Git aktivieren und interaktiv im Alltag prüfen.
- [ ] Terminal und Editor auswählen und konfigurieren.
- [ ] herdr-Tastenkürzel, vim-nav und t/wt-Integration aus playground gezielt übernehmen.
- [ ] Niri und Noctalia neben Plasma einrichten und Alltagstauglichkeit prüfen.
- [ ] Gaming mit Steam/Proton und GPU-Offload prüfen.
- [ ] Erste lokale AI-Laufzeit mit CUDA aufsetzen und passende Modelle auswählen.
- [ ] MacBook und red nach Bestandsaufnahme einzeln anbinden.
- [ ] Raspberry-Modelle, Betriebssysteme und gewünschte Update-Linien erfassen.

## Offene Entscheidungen

- Geräte-Hostname; aktuell `nixos`, die Flake-Auswahl entspricht dem Hostnamen. Umbenennung über die `hostName`-Bindung im Hostmodul und einmalig `sudo nixos-rebuild switch --flake .#NEUER-NAME` aus dem Repository.
- Gewünschte Shell, Terminal und Editor sowie globale Werkzeuge gegenüber Projekt-devShells.
- Separate Versionsgruppen erst bei konkretem Bedarf.
- Geheimnisse und Zugangsdaten erst mit festgelegtem Schlüssel-/Backup-Konzept einbinden.

Dieses Repository enthält System-Betriebswissen. Persönliche Recherche und allgemeine Notizen bleiben zunächst im separaten brain-Repository.
