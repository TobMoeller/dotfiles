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
- [x] Suspend-then-Hibernate als Deckelaktion eingerichtet und unter Niri mit automatischem Übergang nach einer Stunde sowie erfolgreichem Resume getestet (2026-10-19).
- [x] Zwischencommit einschließlich Suspend und Hibernate erstellt; kombinierter Übergang inzwischen ebenfalls bestätigt.
- [ ] Gestaffelte Generationen-Aufbewahrung umsetzen: letzte 5 Generationen, je ein Stand pro Tag für 3 Tage, pro Woche für 4 Wochen und pro Monat für 3 Monate; Überschneidungen zusammenfassen. Zusätzlich laufendes System, Boot-Ziel und einen markierten bewährten Stand schützen. Erst Vorschau prüfen, dann Ausdünnung, Garbage Collection und Aktualisierung des Bootmenüs ergänzen. Noch keine automatische Löschung eingerichtet.
- [x] SSH-Schlüssel vom Benutzer bei GitHub hinterlegt; `origin` auf `git@github.com:TobMoeller/dotfiles.git` umgestellt.
- [x] SSH-Verbindung zu GitHub erfolgreich authentifiziert (Benutzer).
- [ ] Ersten Push von `nixos-foundation` durchführen (Benutzer; Schlüssel mit Passphrase). Der ursprüngliche Name kollidierte mit dem bestehenden Remote-Branch `rebuild`.
- [x] Gemeinsame Git-Konfiguration und private ThinkPad-Identität deklarieren; Arbeitsidentität folgt beim Arbeitsgerät.
- [x] zsh mit nativer Konfiguration deklarieren und bauen.
- [x] Starship mit nativer TOML und stets sichtbarer Befehlslaufzeit deklarieren und bauen.
- [x] Starship aktiviert; erster visueller Benutzertest erfolgreich.
- [ ] Starship später optimieren: Ein-/Zweizeiler, Farben, Git-Details, Projektmodule, Vi-Modus-Anzeige und Verhalten in herdr. Befehlslaufzeit bleibt auf Wunsch immer sichtbar. Native TOML-Datei: `modules/features/starship/starship.toml`.
- [x] zsh/Git aktiviert; Grundbedienung geprüft. Weitere Optimierungen folgen einzeln.
- [ ] Ghostty aktivieren und mit zsh/Starship/herdr prüfen; native Konfiguration, Catppuccin Mocha und MesloLGS NF als Ausgangspunkt.
- [x] Ghostty samt nativer Konfiguration und Schrift validieren und bauen.
- [ ] Neovim-Konfiguration aus `playground` gezielt überführen (eigener größerer Schritt): native Lua-Dateien, Plugins, LSP, Completion und Projektwerkzeuge.
- [x] Gewohnte zsh-Shortcuts im Vi-Insertmodus ergänzt; Caps Lock → Escape über keyd deklariert.
- [ ] Caps-Lock-Remapping aktivieren und die Insertmodus-Tastenkürzel interaktiv prüfen.
- [ ] Steam-Fensterbedienung prüfen: native Menüs/Titelleiste des Clients und Login-Dialogs von Niris Dekorationen unterscheiden. Keine globale Dekorationsumstellung als vermeintliche Steam-spezifische Lösung.
- [ ] Grafischen Boot-/LUKS-Bildschirm mit Plymouth einrichten.
- [x] herdr-Tastenkürzel, vim-nav und Projekthelfer `t` gezielt übernehmen; `wt` verwendet die native Worktree-Verwaltung.
- [x] herdr aktiviert und erster Benutzertest erfolgreich.
- [ ] Neovim-Seite der herdr-Split-Navigation beim Editor-Umzug ergänzen.
- [ ] Niri/Noctalia als zusätzliche Sitzung aktivieren und ersten Login prüfen (Terminal, Launcher, Portale, Audio, WLAN, Helligkeit, Sperre und Deckelaktion).
- [x] Niri/Noctalia-Grundkonfiguration deklarieren, mit nativen Validatoren prüfen und System bauen.
- [ ] Niri/Noctalia im Alltag optimieren: Skalierung/Monitore, Shortcuts, Theme, Clipboard und Screenshots.
- [ ] Gewünschte Touchpad-Gesten prüfen: drei Finger links/rechts für Zurück/Vor, vier Finger horizontal für Workspaces, vertikal Übersicht. Niri 26.04 hat feste Gesten; eine Lösung muss die eingebauten Aktionen ersetzen, statt zusätzlich auszulösen.
- [x] Workspace-Tasten entschieden: Super+I/U bleiben; Super+J/K fokussieren Fenster innerhalb einer Spalte.
- [ ] Themes, Schriftgrößen und Hintergrundbilder für Niri/Noctalia/Ghostty abstimmen; Bildquellen und Lizenzen festhalten.
- [ ] Steam/Proton-Gaming aktivieren: Anmeldung, erstes Spiel, NVIDIA-Offload, GameMode und MangoHud prüfen; Gamescope anschließend separat testen.
- [x] Steam, GE-Proton, GameMode, MangoHud, Gamescope und Protontricks deklarieren und System bauen.
- [ ] Lokale KI: CUDA-/GPU-Unterstützung prüfen und eine erste Laufzeit auswählen (z. B. Ollama oder llama.cpp); Systemdienste und Projektumgebungen bewusst trennen.
- [ ] Lokale KI: erstes Modell für 16 GiB VRAM auswählen und GPU-Nutzung, Geschwindigkeit, Speicherbedarf und Leistungsaufnahme messen; Chat-Oberfläche und Coding-Anbindung anschließend ergänzen.
- [x] devShell für das Dotfiles-Repo und kleine unabhängige Projektvorlage bereitstellen; direnv/nix-direnv mit Shell-Anbindung deklarieren.
- [ ] direnv aktivieren und im Alltag prüfen; erste stackspezifische devShell in einem Anwendungsprojekt einrichten und testen.
- [ ] Weitere eigenständige Projektvorlagen bereitstellen, zuerst PHP mit passender Composer-Version; weitere Stacks nach Bedarf. Die Basisvorlage bleibt klein.
- [ ] Container-Setup entscheiden: Docker, rootless Docker oder Podman anhand der benötigten Compose-/Projekt-Workflows vergleichen und anschließend gezielt konfigurieren.
- [ ] `brain` und Obsidian überführen: Repo/Vault-Pfad festlegen, Notizen synchronisieren, Plugins und portable Konfiguration prüfen; persönliche Inhalte und Zugangsdaten außerhalb der öffentlichen Dotfiles halten.
- [ ] Gemeinsame Skills für Codex/GPT und Claude pflegen: gemeinsame Quellen, unterstützte Dateiformate und Symlinks/Adapter prüfen; an einem Skill testen und produktspezifische Regeln getrennt halten.
- [ ] Aktualisierte playground-Pipeline (`44ab6f2`) gezielt überführen: `wt agent/lead`, Bootstrap-Hooks und Bereitschaftsmarker, `wt testdb`, `main/back` sowie `wl`, `wl-write`, `wl-runden` und `gitday` prüfen. Die neue native Worktree-Verwaltung ersetzt diese zusätzlichen Abläufe noch nicht; mit Projekt-devShells und gemeinsamen Skills abstimmen.
- [ ] MacBook und red nach Bestandsaufnahme einzeln anbinden.
- [ ] Raspberry-Modelle, Betriebssysteme und gewünschte Update-Linien erfassen.

## Offene Entscheidungen

- Geräte-Hostname; aktuell `nixos`, die Flake-Auswahl entspricht dem Hostnamen. Umbenennung über die `hostName`-Bindung im Hostmodul und einmalig `sudo nixos-rebuild switch --flake .#NEUER-NAME` aus dem Repository.
- Globale Werkzeuge gegenüber Projekt-devShells; Shell ist zsh, Prompt Starship, Terminal Ghostty und Editor künftig Neovim.
- Prompt-Alternativen bei späterem Bedarf: [zsh-eigener Prompt mit vcs_info](https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#Version-Control-Information), [Pure](https://github.com/sindresorhus/pure) oder [Powerlevel10k](https://github.com/romkatv/powerlevel10k) (laut Projekt nur eingeschränkter Support). Zuerst [Starship-Konfiguration und Presets](https://starship.rs/config/) ausprobieren.
- Separate Versionsgruppen erst bei konkretem Bedarf.
- Geheimnisse und Zugangsdaten erst mit festgelegtem Schlüssel-/Backup-Konzept einbinden.

Dieses Repository enthält System-Betriebswissen. Persönliche Recherche und allgemeine Notizen bleiben zunächst im separaten brain-Repository.
