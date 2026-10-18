# dotfiles

Neue Flake für meine Systeme und persönliche Entwicklungsumgebung. Ausgangspunkt ist das ThinkPad P1 Gen 4; MacBook, red und Raspberry Pis folgen einzeln. Die bisherige Konfiguration bleibt in der Git-Historie und auf `playground` erhalten.

## Einstieg

`flake.nix` lädt die äußeren flake-parts-Module explizit. Diese stellen NixOS- und Home-Manager-Bausteine bereit. `modules/hosts/thinkpad.nix` wählt die Bausteine und veröffentlicht die Konfiguration unter dem dort festgelegten Hostnamen, aktuell `nixosConfigurations.nixos`.

```bash
./scripts/rebuild              # sudo nixos-rebuild switch --flake .
```

Home Manager setzt `DOTFILES` auf den Repository-Pfad. Damit funktioniert nach der Aktivierung und einem neuen Login auch von außerhalb: `"$DOTFILES/scripts/rebuild"`.

- [Aufbau und Konfigurationsfluss](docs/architecture.md)
- [Prüfen und später aktivieren](docs/bootstrap.md)
- [Nächste Schritte](docs/roadmap.md)
- [Prüfergebnis des ersten Systembuilds](docs/validation.md)
- [Repository-Scripts](scripts/README.md)
- [ThinkPad: Grafik und Energiesparen](docs/thinkpad-hardware.md)
- [Swap und Hibernate testen](docs/hibernate.md)
- [zsh und Git](docs/shell-and-git.md)
- [Erste Niri-/Noctalia-Sitzung](docs/niri.md)

## Aktueller Umfang

- NixOS 26.05, passende Home-Manager-Release-Linie und flake-parts.
- Bestehende ThinkPad-Installation einschließlich Hardware, Verschlüsselung und Plasma als Basis; Hostname und Flake-Auswahl `nixos`, Geräteverzeichnis `thinkpad`.
- Integrierter Home Manager für `tobias`.
- Erstes herdr-Feature mit kleiner nativer TOML-Konfiguration, direkt ins Checkout verknüpft.
- Persönlicher PATH mit `~/.local/bin`, npm-Prefix `~/.local` und `dotfiles-rebuild` als verknüpfter Repo-Befehl eingerichtet.
- zsh als ThinkPad-Login-Shell, Starship mit direkt bearbeitbarer TOML und gemeinsame Git-Einstellungen mit privater Host-Identität; Aktivierung siehe Shell-Dokumentation.
- NVIDIA-Treiber und PRIME-Offload nach Neustart und Suspend getestet; auf diesem Gerät coarse-grained Runtime-PM als Workaround für GSP-Abstürze.
- 80-GiB-Swapdatei und Hibernate über UEFI/systemd aktiviert; Wiederaufnahme samt NVIDIA, Audio, Netzwerk und erhaltener Sitzung erfolgreich getestet.

Suspend-then-Hibernate beim Zuklappen ist für Plasma aktiviert; der kombinierte Übergang ist noch nicht getestet. Niri/Noctalia ist als zusätzliche Sitzung vorbereitet; der erste Login steht aus. Die vollständige persönliche Werkzeugauswahl sowie andere Hosts folgen. Konfigurationsänderungen werden durch Bearbeiten des Repositorys nicht automatisch aktiviert.
