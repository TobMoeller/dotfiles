# ThinkPad: prüfen und aktivieren

Die vorhandene Installation wird nicht neu partitioniert. `hosts/thinkpad/hardware-configuration.nix` wurde unverändert aus `/etc/nixos` übernommen und gilt ausschließlich für dieses Gerät.

## Prüfen

```bash
cd ~/code/tobmoeller/dotfiles
nix --extra-experimental-features 'nix-command flakes' flake check --no-build
nix --extra-experimental-features 'nix-command flakes' eval --raw .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath
```

Bei einer Git-Flake müssen neue Dateien dem Git-Index bekannt sein (`git add <dateien>`). Änderungen vor dem Staging prüfen; ein Commit ist für die lokale Auswertung nicht erforderlich.

## Bauen, ohne zu aktivieren

```bash
nixos-rebuild build --flake .
```

Das Ergebnis liegt unter `result`. Ein erfolgreicher Build ersetzt keine Prüfung des Boot-, Grafik- und Suspend-Verhaltens am Gerät.

## Später bewusst aktivieren

Vorher die Änderungen an System- und Home-Konfiguration prüfen und vorhandene `~/.config/herdr/config.toml` sichern, falls sie kollidiert. Home Manager überschreibt vorhandene fremde Dateien standardmäßig nicht.

```bash
sudo nixos-rebuild dry-activate --flake .
export DOTFILES="$HOME/code/tobmoeller/dotfiles" # Bis die neue Login-Umgebung aktiv ist
./scripts/rebuild
```

Das Script führt `sudo nixos-rebuild switch --flake .` aus. `nixos-rebuild` erkennt den Hostnamen selbst. `dry-activate` baut und zeigt geplante Aktivierungsänderungen.

Auf einer frischen Installation ohne aktivierte Flakes lautet der einmalige erste Aufruf:

```bash
sudo nixos-rebuild switch --flake . --option experimental-features 'nix-command flakes'
```

Nach Aktivierung sind Flakes dauerhaft eingeschaltet. Die bestehende `/etc/nixos`-Konfiguration bleibt als Referenz erhalten. Nach Ab- und erneutem Anmelden setzt Home Manager `DOTFILES` dauerhaft auf den konfigurierten Repository-Pfad. Das Script wechselt über diese Variable ins Checkout und funktioniert damit aus jedem Arbeitsverzeichnis. Ein direkter Aufruf `sudo nixos-rebuild switch --flake .` aus dem Repository erkennt den Hostnamen ebenfalls, sobald Flakes aktiviert sind.

## Umgebung in einem bereits offenen Bash-Terminal laden

```bash
source ~/.profile
```

Damit stehen DOTFILES, npm-Prefix und PATH unmittelbar in diesem Terminal zur Verfügung. Der Befehl zum Rebuild heißt `dotfiles-rebuild`; `DOTFILES` selbst ist eine Variable, kein Befehl. Neue Bash-Terminals laden die Variablen nach Aktivierung der Bash-Einbindung auch über `.bashrc`.

## Updates

```bash
nix flake update nixpkgs home-manager
nix flake check --no-build
```

Lockfile-Diff prüfen und anschließend bauen. Andere Geräte werden dadurch nicht aktiviert. `system.stateVersion` und `home.stateVersion` nicht als Teil eines Paketupdates anheben.
