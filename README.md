# Dotfiles

Ghostty: Hosts importieren bei Bedarf `modules/ghostty.nix`. Die native
Konfiguration unter `config/ghostty/config` nutzt MesloLGS NF, Größe 14 und
Catppuccin Mocha. Linux erhält Ghostty und die Schrift über Nix/Fontconfig.
Auf devbox-01 stellt der Home-Manager-nixGL-Wrapper Mesa-Grafikbibliotheken
bereit, auch für den Desktop-Launcher. Kernel-/Display-Treiber bleiben Sache
des Betriebssystems; NVIDIA-Hosts benötigen eine passende andere Anbindung.
Auf NixOS bleibt nixGL unkonfiguriert. Für macOS muss die native Ghostty-App
separat installiert und die Schrift für macOS registriert werden.
Die Schrift wird auf dem Gerät benötigt, auf dem das Terminalfenster läuft;
die VM-Konfiguration verändert keine lokalen SSH-Clients.

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
hms                                      # gleicher Switch, aus jedem Verzeichnis
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

Neovim: `<Leertaste>n` schaltet nvim-tree links ein/aus und zeigt die aktuelle
Datei. Im Baum öffnet Enter Dateien/Ordner,
`a` legt an, `r` benennt um, `R` aktualisiert, `g?` zeigt die Tastenbelegung.
Git-Integration, Diagnostik und Dateisystem-Watcher sind im Baum deaktiviert.
`-` oder `<Leertaste>e` öffnet Oil im aktuellen Fenster: Enter öffnet einen
Eintrag, `-` geht nach oben, `g?` zeigt Hilfe. Dateinamen wie Text bearbeiten;
`:w` wendet die Dateioperationen nach Bestätigung an.
Strg+N/P wechselt im Normalmodus native Tabs (Fensterlayouts), `<Leertaste>tn`
legt einen Tab an, `<Leertaste>tc` schließt ihn. Buffer sind tabübergreifend.
`<Leertaste>g` öffnet Neogit, `bn`/`bp` nach Leertaste wechseln Buffer,
`ff` sucht Dateien, `fg` Projekttext, `fb` offene Buffer und `fh` zuletzt
geöffnete Dateien über fzf-lua. Strg+J/K bewegt die Auswahl, Enter öffnet im
aktuellen Fenster und Strg+T im neuen Tab,
Esc schließt. Die Suche startet im Arbeitsverzeichnis und beachtet Git-Ignores.
`sv`/`sh` teilen vertikal/horizontal,
`se` gleicht Fenstergrößen an. Im Visual-Modus behalten `<`/`>` die Auswahl;
`p` ersetzt sie, ohne den bisherigen Registerinhalt zu verlieren.

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
Vi-Modus: `Esc` wechselt zu Normal, `i` zurück zu Insert; neue Eingaben starten
in Insert. `Strg+E` übernimmt den grauen History-Vorschlag in beiden Modi.
`config/zsh/p10k.zsh` bestimmt den kompakten Pfad-/Git-Prompt.
Die Startzeit wird erst beim Abschicken im Prompt eingeblendet.
Eine Abschlusszeile wird derzeit nicht angezeigt.
Fehler und Abbrüche färben nur den Prompt-Pfeil rot.
History und Completion-Cache liegen unter XDG state/cache, Plugins kommen aus Nix.

Für Ubuntu-SSH-Logins nach der Aktivierung einmalig die Login-Shell setzen:

```sh
grep -qxF "$HOME/.nix-profile/bin/zsh" /etc/shells || \
  printf '%s\n' "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
chsh -s "$HOME/.nix-profile/bin/zsh"
```

Das gilt ab dem nächsten Login. Herdr startet Zsh bereits direkt.

## Persönliche PHP-Umgebung

Neovim aus `dev` starten, damit Language Server und Tools die Projektumgebung
erben. Ein Verzeichniswechsel in einem laufenden Neovim wechselt die DevShell
nicht; für andere Laufzeiten eine separate Neovim-Instanz starten. Mason wird
beim Start eingerichtet und hängt seine Tools hinten an PATH an, sodass
DevShell-Werkzeuge Vorrang behalten. Die LSP-Aktivierung wird separat nach
Dateityp und Projektroot konfiguriert; derzeit sind keine Server aktiviert.

```sh
cd ~/code/dev-environments/shop
nix flake init -t "path:$DOTFILES#php"
# Kurzform: flake-init php (Hilfe: flake-init --help)
dev
```

`DOTFILES` wird aus `dotfiles.repoRoot` des Hosts gesetzt und in jeder Zsh
erneut geladen. Nach der Aktivierung genügt `exec zsh`.
Die Vorlage liegt unter `templates/php/`; `nix flake init` kopiert sie in das
aktuelle Verzeichnis. Bestehende abweichende Dateien werden nicht überschrieben.
PHP-Version, Extensions, INI-Werte und Node-Version in der Kopie anpassen.
Beim ersten Entwickeln wird `flake.lock` erzeugt; für reproduzierbare Versionen
aufbewahren. Änderungen an der Vorlage verändern vorhandene Kopien nicht.

Aus einem separaten Team-Repository die persönliche Umgebung starten:

```sh
dev "path:$HOME/code/dev-environments/shop"
```

`exit` verlässt die Umgebung. PHP, Composer, Node/npm, Git und unzip kommen aus
Nix; `vendor/` und `node_modules/` bleiben normale Projektabhängigkeiten.

`dev` startet `nix develop` mit der persönlichen Zsh inklusive Vi-Modus,
Completions und Prompt. Projektwerkzeuge behalten Vorrang im PATH; der Prompt
zeigt in Nix-Shells ein kleines `dev`. Ohne den Helfer gilt weiterhin
`nix develop --command zsh`; ein bloßes `nix develop` startet standardmäßig Bash.

## Brain (optional pro Host)

`modules/brain.nix` importieren und `dotfiles.brain.enable = true` setzen.
`BRAIN` zeigt standardmäßig auf `~/code/knowledge/brain`; der Pfad lässt sich
mit `dotfiles.brain.path` ändern. Nach Aktivierung lädt `exec zsh` die Variable.

```sh
"$DOTFILES/scripts/install-brain"
# Alternativ mit bereits eingerichteter SSH-Identität:
"$DOTFILES/scripts/install-brain" git@github.com:TobMoeller/brain.git
```

Der Helfer prüft den Zugriff vor dem Clone und lehnt vorhandene Ziele ab.
Zugangsdaten werden separat eingerichtet; weder Secrets noch Notizen gelangen
in den Nix Store. Home-Manager-Switches klonen, pullen, resetten oder löschen
Brain nicht. Deaktivieren lässt den Checkout bestehen; eine neue Login-Sitzung
verwirft zuvor geerbte Umgebungsvariablen.

`dotfiles.brain.syncthing.enable = true` installiert zunächst nur die CLI.
Dienststart, Geräteverbindung und Ordnerfreigabe werden separat eingerichtet.
Dabei denselben Brain-Pfad verwenden und `.git` über die Syncthing-Ignore-Regeln
des Ordners ausschließen. Jedes Gerät behält eigene Git-Metadaten; parallele
Git-Operationen vermeiden und synchronisierte Änderungen vor Commits prüfen.
Auf devbox-01 ist Syncthing ausgeschaltet; GitHub-Zugriff ist noch einzurichten.
