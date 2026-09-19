# Dotfiles

Auf frischem Ubuntu mit Git und curl (Nix darf bereits manuell installiert sein):

```sh
./scripts/install-home
```

Erkennt/lädt Nix oder startet den offiziellen Multi-User-Installer. Verlinkt
`nix/nix.conf` nach `~/.config/nix/nix.conf` (beachtet `XDG_CONFIG_HOME`), ohne
bestehende Dateien zu überschreiben. Benötigt keine systemweite Flake-Freischaltung.
Mit `--build --no-out-link` nur bauen, ohne Home-Manager-Aktivierung.

Startet danach die gepinnte Home-Manager-CLI und führt `switch` aus. Home Manager wählt
`user@host` automatisch; aktuell ist `tobias@devbox-01` konfiguriert.

Später aus dem Repository:

```sh
home-manager switch --flake .
nix-collect-garbage                       # Alias in Zsh: nix-gc
nix-collect-garbage --delete-older-than 30d # entfernt auch alte Rückrollpunkte
```

## Aufbau

- `hosts/`: Benutzer, Live-Checkout-Pfad und Auswahl der Fachmodule.
- `modules/`: Pakete und Links, keine große gemeinsame Hostkonfiguration.
- `config/`: native Konfiguration, per Out-of-store-Symlink eingebunden.
- `scripts/`: einmalig aufgerufene Installations- und Reparaturhelfer.
- `bin/`: eigene Alltagsprogramme, bei Bedarf einzeln nach `~/.local/bin` verlinkt.

Native Änderungen brauchen nur den jeweiligen Programm-Reload. Paket- und
Linkänderungen brauchen einen Switch. HM-Rollbacks stellen keine alten Inhalte
der Live-Dateien wieder her; dafür ist Git zuständig.

Zustand gehört in XDG data/state/cache, nicht ins Repository. Neovim-Plugins
werden von lazy.nvim verwaltet; der Manager selbst kommt gepinnt aus Nix.
Nach dem ersten Start `:Lazy sync` ausführen; es gibt keine automatischen Downloads
beim Start. Neogit: `:Neogit` / `<Leertaste>g`. Mason: `:Mason` für LSP-Server,
Formatter und andere Tools. Mason installiert Werkzeuge; die sprachspezifische
Neovim-LSP-Konfiguration folgt separat (PHP/Laravel als nächster Schritt).
Plugin-Installationen liegen unter Neovims data-Verzeichnis, Lazy-Lockfile unter
state, Mason-Tools unter data/mason. Node/npm, Python und Archivwerkzeuge kommen
aus Nix; zusätzliche Laufzeiten hängen vom gewählten Mason-Paket ab. Herdr verwaltet derzeit auch Zustand in seinem
Config-Verzeichnis, deshalb nur einzelne Konfigurationsdateien verlinken.
Git-Identität und Signing stehen optional in `~/.config/git/local.inc`.

Nix-Konfiguration und persönliche Pakete einschließlich Codex, Herdr und ripgrep
gehören zu den Dotfiles. Ansible ist dafür keine Voraussetzung. Neue Geräte
bekommen eine Host-Komposition mit eigenem Benutzer und `dotfiles.repoRoot`;
aktuell ist nur devbox-01 definiert. Alte Konfiguration: Branch `playground`.
Lokale Notizen (`docs/`) und Testskripte (`.local/`) werden nicht versioniert.

## Navigation und Themes

Strg+H/J/K/L wechselt zwischen Neovim-Splits und am Rand zum benachbarten
Herdr-Pane. Das lokale `vim-nav`-Plugin wird beim HM-Switch registriert;
Herdr-Keybindings werden mit `herdr server reload-config` neu geladen.
Bei Herdr-Remote-Verbindungen gegebenenfalls Server-Keybindings wählen.

`:Theme` oder `<Leertaste>ut` wählt Catppuccin, Tokyo Night, Dracula oder die
JetBrains-Portierungen Darcula (`darcula`) und Dark (`dark`);
`:Theme dracula` setzt direkt eine Variante. Die Auswahl bleibt unter Neovims
state-Verzeichnis gespeichert. Standard ist Catppuccin Mocha.

## Shell

Zsh nutzt Powerlevel10k, zusätzliche Completions, History-Vorschläge und
Syntax-Highlighting. `exec zsh` lädt die aktuelle Konfiguration.
`config/zsh/p10k.zsh` bestimmt den Prompt: Uhrzeit beim Abschicken,
Git-Status und `prev:` als Laufzeit des vorherigen Befehls.
History und Completion-Cache liegen unter XDG state/cache, Plugins kommen aus Nix.

Für Ubuntu-SSH-Logins nach der Aktivierung einmalig die Login-Shell setzen:

```sh
grep -qxF "$HOME/.nix-profile/bin/zsh" /etc/shells || \
  printf '%s\n' "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
chsh -s "$HOME/.nix-profile/bin/zsh"
```

Das gilt ab dem nächsten Login. Herdr startet Zsh bereits direkt.

## Persönliche PHP-Umgebung

```sh
./scripts/new-php-env ~/code/dev-environments/shop 8.4
cd ~/code/mein-shop
nix develop "path:$HOME/code/dev-environments/shop" --command zsh
```

Der Generator erstellt eine Flake samt Lockfile in einem neuen Verzeichnis;
vorhandene Ziele bleiben unangetastet. Enthalten sind PHP, passender Composer,
Node.js 24 samt npm, Git und unzip. Version (Standard 8.4), Extensions und PHP-Einstellungen lassen
sich in der erzeugten Flake anpassen. Ein Lock-/Evaluationsfehler lässt die
Dateien zur Korrektur stehen; die Umgebung wurde dann noch nicht validiert.

`exit` verlässt die Umgebung. Im Team-Repository wird nichts angelegt;
Pakete liegen im Nix Store. Composer verwaltet Projektabhängigkeiten weiterhin
normal über `composer.json`/`composer.lock` und `vendor/`.
Node lässt sich über `pkgs.nodejs_24` in der erzeugten Flake auswählen;
npm verwaltet Projektabhängigkeiten über `package.json`/`package-lock.json`
und `node_modules/`. Der Generator installiert keine Projektabhängigkeiten.
