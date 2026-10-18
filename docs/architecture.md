# Aufbau

## Vom Einstiegspunkt zur Konfiguration

```text
flake.nix + flake.lock
  → modules/hosts/thinkpad.nix
      → nixosConfigurations.nixos
          → modules.nixos.thinkpad
              → modules.nixos.base
              → modules.nixos.nvidia-prime
              → modules.nixos.hibernate
              → hosts/thinkpad/configuration.nix
                  → hardware-configuration.nix
              → Home-Manager-NixOS-Integration
                  → home-manager.users.tobias
                      → modules.homeManager.tobias
                          → dotfiles
                          → herdr
```

`thinkpad` benennt das Geräteverzeichnis und das interne Modul. Der Netzwerk-Hostname und der Name der Flake-Ausgabe sind dagegen `nixos`. Beide stammen aus derselben `hostName`-Bindung in `modules/hosts/thinkpad.nix`.

`scripts/rebuild` führt `sudo nixos-rebuild switch --flake .` im Repository aus. `nixos-rebuild` selbst wählt anhand des laufenden Hostnamens die Flake-Ausgabe. Die Flake liest keinen Hostnamen aus ihrer Umgebung: Sie bleibt unabhängig vom auswertenden Rechner. Bei einer Umbenennung setzt man `hostName` im Hostmodul neu und ruft einmal `sudo nixos-rebuild switch --flake .#NEUER-NAME` aus dem Repository auf. Nach Aktivierung wird der neue Hostname automatisch erkannt.

## Drei Modulkontexte

1. **flake-parts:** Dateien unter `modules/` organisieren die Flake und stellen Bausteine bereit.
2. **NixOS:** `flake.modules.nixos.*` konfiguriert Betriebssystem, Dienste, Treiber und Konten.
3. **Home Manager:** `flake.modules.homeManager.*` konfiguriert persönliche Pakete und Dateien.

Eine äußere Feature-Datei kann sowohl NixOS- als auch Home-Manager-Teile bereitstellen. Das ist der dendritische Ansatz. Laden der äußeren Datei aktiviert ihre inneren Bausteine nicht automatisch: Der Host oder das Benutzerprofil importiert sie ausdrücklich. Wir verwenden zunächst weder automatische Verzeichnisimporte noch ein zusätzliches Framework.

`hosts/thinkpad/` enthält gewöhnliche gerätespezifische NixOS-Dateien. Insbesondere bleibt die generierte Hardwaredatei außerhalb des Baums der äußeren flake-parts-Module. Ein Modul muss nicht wiederverwendbar sein.

`modules/features/nvidia-prime.nix` stellt Treiber, Offload und Energieverwaltung bereit. Die PCI-Adressen der GPUs stehen dagegen im ThinkPad-Hostmodul. Auf einem anderen Hybrid-Gerät kann dasselbe Feature mit dessen eigenen Adressen verwendet werden; MacBook und Raspberry Pi importieren es nicht.

Das Hibernate-Feature verwendet UEFI und systemd im Initrd für die automatische Wiederaufnahme. Die Swapdatei mit gerätespezifischer Größe steht im Hostmodul. Auf dem ThinkPad liegt sie im bestehenden verschlüsselten Root-Dateisystem. Details und der manuelle Test stehen in `docs/hibernate.md`; andere Geräte übernehmen dieses Feature erst nach Prüfung ihrer Boot- und Speicher-Konfiguration.

Das ThinkPad wählt außerdem das Home-Manager-Feature `plasma-sleep`. Dessen native `powerdevilrc` legt die kombinierte Schlafaktion für Plasma fest; die Verzögerung und das Verhalten am Netzteil definiert systemd im Hibernate-Feature. Ohne Desktop-Energieverwaltung greift dessen logind-Deckelaktion. Die Plasma-Datei bleibt direkt im Checkout bearbeitbar.

## Benutzer und Abweichungen

Das Betriebssystemkonto steht in der Hostkonfiguration. `modules.homeManager.tobias` ist eine gemeinsame persönliche Umgebung mit herdr, npm, zsh und Git. Benutzername, Home-Verzeichnis und Home-Manager-Kompatibilitätsversion setzt der Host. Die private Git-Identität steht ebenfalls im ThinkPad-Host; gemeinsame Git-Einstellungen enthalten keine Identität. Die NixOS-zsh-Integration und die Auswahl der Login-Shell werden ausdrücklich auf dem Host aktiviert, die native interaktive Konfiguration bleibt im zsh-Feature.

Module können bestehende Optionen setzen. `lib.mkDefault` kennzeichnet bewusst überschreibbare Vorgaben; normale Zuweisungen überschreiben diese. Widersprüchliche gleichrangige einfache Werte führen zu einem Fehler. Importreihenfolge bedeutet nicht „letzte Datei gewinnt“. Eigene Optionen führen wir nur bei konkretem Bedarf ein.

## Native Konfiguration und direkte Symlinks

Das separate Home-Manager-Feature `starship` stellt den Prompt und seine
zsh-Integration bereit. `modules/features/starship/starship.toml` wird direkt
als `~/.config/starship.toml` verknüpft. Tastenkürzel bleiben im zsh-Feature;
ein anderer Prompt erfordert keine Änderung der Shell-Bedienung.

`modules/features/herdr/config.toml` bleibt normales TOML. Home Manager installiert herdr und verknüpft die Datei über `mkOutOfStoreSymlink` direkt mit dem Checkout. Es gibt keine Abhängigkeit auf die alten t/wt-Skripte oder ein noch nicht eingerichtetes zsh.

Standardpfad ist `~/code/tobmoeller/dotfiles`. Ein Host kann in seinem Home-Manager-Modul `dotfiles.repositoryPath` auf einen anderen absoluten Pfad setzen. Der Pfad muss bei Aktivierung und Nutzung existieren. Umzug des Checkouts erfordert eine entsprechende Anpassung und erneute Aktivierung.

Aus diesem Pfad setzt das dotfiles-Feature auch `home.sessionVariables.DOTFILES`. Shell-Scripts können dadurch direkt `cd "$DOTFILES"` verwenden. Die aktuelle Bash wird über Home Manager eingebunden, damit sie die Sitzungsvariablen lädt. Bei einer späteren Shell-Auswahl wird die entsprechende Integration ebenfalls eingerichtet. Nix selbst verwendet weiterhin die deklarierte Option, keine aus der Umgebung gelesene Variable.

Home Manager lädt die Bash-Sitzungsvariablen regulär über `.profile` für Login-Shells. Zusätzlich wird die erzeugte `hm-session-vars.sh` in `.bashrc` geladen, damit auch normale, nicht als Login-Shell gestartete GUI-Terminals DOTFILES, npm-Prefix und PATH erhalten. Bereits offene Shells aktualisieren ihre Umgebung durch einen Rebuild nicht automatisch.

Das gemeinsame Benutzerprofil ergänzt `~/.local/bin` über `home.sessionPath`. Das npm-Feature setzt `NPM_CONFIG_PREFIX` auf `~/.local`; npm installiert globale Befehle damit in dieses bin-Verzeichnis. Eine vorhandene `.npmrc` wird nicht übernommen oder überschrieben. Der ThinkPad-Host verknüpft zusätzlich `dotfiles-rebuild` in `~/.local/bin` direkt mit dem Rebuild-Script im Repository.

Dateiänderungen wirken nach dem Neuladen des Programms. Ein System-Rollback setzt diese Dateien nicht zurück; dafür dient Git. Wer eine unveränderliche Variante möchte, kann stattdessen eine normale Nix-Pfadquelle verwenden. Native Dateiformate und unveränderliche Bereitstellung schließen sich nicht aus.

## Versionen und weitere Plattformen

Ein gemeinsames Lockfile, manuelle Aktivierung pro Gerät. Für einen früheren Stand verwenden wir den passenden Git-Commit einschließlich Lockfile. Geräte bleiben unverändert, bis dort eine neue Konfiguration aktiviert wird.

Home Manager folgt hier dem System-Nixpkgs. herdr kommt separat aus dem ebenfalls fixierten Input `nixpkgs-tools` (unstable), da es im 26.05-Paketsatz noch nicht enthalten ist. Dieser Input ersetzt weder System-Nixpkgs noch den Home-Manager-Paketsatz. Er lässt sich gezielt mit `nix flake update nixpkgs-tools` aktualisieren. Für dauerhaft unterschiedliche Release-Linien pro Gerät lassen sich später getrennte Input-Gruppen ergänzen. `stateVersion` ist keine Auswahl der Paketversion.

Weitere Systeme können dieselben Home-Manager-Bausteine verwenden. Auf anderem Linux wird Home Manager eigenständig eingebunden, auf macOS eigenständig oder über nix-darwin. Es werden noch keine ungetesteten Host-Ausgaben versprochen.
