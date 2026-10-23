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
- [Offene Dock-/Schlafdiagnose](docs/dock-diagnostics.md)
- [zsh und Git](docs/shell-and-git.md)
- [Erste Niri-/Noctalia-Sitzung](docs/niri.md)
- [Steam, Proton und Gaming-Werkzeuge](docs/gaming.md)
- [herdr, Projekte und Worktrees](docs/herdr.md)
- [Neovim, Laravel-LSP und große Dateien](docs/neovim.md)
- [Projekt-devShells und direnv](docs/development.md)
- [Docker, Compose und Containerdaten](docs/docker.md)
- [AirPods Pro 2 mit LibrePods](docs/airpods.md)
- [Generationen aufbewahren und bereinigen](docs/generations.md)

## Aktueller Umfang

- NixOS 26.05, passende Home-Manager-Release-Linie und flake-parts.
- Bestehende ThinkPad-Installation einschließlich Hardware, Verschlüsselung und Plasma als Basis; Hostname und Flake-Auswahl `nixos`, Geräteverzeichnis `thinkpad`.
- Integrierter Home Manager für `tobias`.
- herdr mit nativer TOML, Pane-Navigation, Projektauswahl und eingebauter Worktree-Verwaltung; Dateien direkt ins Checkout verknüpft.
- Projektumgebungen mit `nix develop`, optionaler direnv-Automatik und einer kleinen Flake-Vorlage; das Dotfiles-Repo liefert eine devShell mit Nix-Formatter und ShellCheck.
- Persönlicher PATH mit `~/.local/bin`, npm-Prefix `~/.local` und `dotfiles-rebuild` als verknüpfter Repo-Befehl eingerichtet.
- zsh als ThinkPad-Login-Shell, Starship mit direkt bearbeitbarer TOML und gemeinsame Git-Einstellungen mit privater Host-Identität; Aktivierung siehe Shell-Dokumentation.
- Ghostty mit nativer Konfiguration, Catppuccin Mocha und MesloLGS NF; Niri-Terminalkürzel verwenden Ghostty nach Aktivierung.
- NVIDIA-Treiber und PRIME-Offload nach Neustart und Suspend getestet; auf diesem Gerät coarse-grained Runtime-PM als Workaround für GSP-Abstürze.
- 80-GiB-Swapdatei und Hibernate über UEFI/systemd aktiviert; Wiederaufnahme samt NVIDIA, Audio, Netzwerk und erhaltener Sitzung erfolgreich getestet.

Suspend-then-Hibernate beim Zuklappen ist eingerichtet und mit automatischem Übergang nach einer Stunde sowie erfolgreicher Wiederaufnahme unter Niri getestet. Niri/Noctalia ist aktiviert. Die vollständige persönliche Werkzeugauswahl sowie andere Hosts folgen. Konfigurationsänderungen werden durch Bearbeiten des Repositorys nicht automatisch aktiviert.
