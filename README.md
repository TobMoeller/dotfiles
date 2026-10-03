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

Zustand gehört in XDG data/state/cache, nicht ins Repository. Neovim und seine
Plugins einschließlich Treesitter-Parser kommen aus Nix; Updates erfolgen mit
Flake-Update und `hms`. Die Lua-Konfiguration bleibt live verlinkt. Es gibt keine
Plugin-Downloads beim Editorstart. Frühere Lazy-Installationen unter data/lazy
und das alte state/lazy-lock.json werden nicht mehr verwendet, aber nicht gelöscht.

`modules/neovim.nix` enthält die Pakete. Unter `config/nvim/lua/config/` liegen
`options.lua`, `lsp.lua`, `theme.lua`, Plugin-Setups in `plugins/` und nach Themen
sortierte Tastenkürzel in `keymaps/`. Ausgangsbasis ist die alte Konfiguration
bei `dc20e5e`; deaktivierte Experimente wurden nicht übernommen. Treesitter nutzt
die aktuelle API ohne doppelte Regex-Hervorhebung. Seine inkrementelle Auswahl
(`v` Enter, Tab/Shift-Tab) arbeitet mit Syntaxknoten; `v` Enter im Visual-Modus
vergrößert ebenfalls auf den Elternknoten statt auf einen eigenen Scope.

Completion kommt von nvim-cmp: Tab/Shift-Tab wählen Vorschläge oder springen in
Snippets, Enter bestätigt, Strg+Leertaste öffnet das Menü, Strg+E schließt es.
PHP (Intelephense), TypeScript/JavaScript, Tailwind und Python (Pyright) kommen
mit Servern aus Nix. Dart, SourceKit, Zig und Go werden ebenfalls angebunden,
wenn ihr Server im PATH verfügbar ist. `:Mason` installiert zusätzliche Tools
unter data/mason; neue Sprachen brauchen außerdem einen Eintrag in `lsp.lua`.
Node/npm, Python und Archivwerkzeuge kommen aus Nix. DevShell-Werkzeuge haben
Vorrang vor Mason. Mit `:checkhealth vim.lsp` lässt sich die Anbindung prüfen.
Herdr verwaltet derzeit auch Zustand in seinem Config-Verzeichnis, deshalb
werden dort nur einzelne Konfigurationsdateien verlinkt.
Git-Identität und Signing stehen optional in `~/.config/git/local.inc`.

Nix-Konfiguration und persönliche Pakete einschließlich Node/npm, Herdr und ripgrep
gehören zu den Dotfiles. Ansible ist dafür keine Voraussetzung. Neue Geräte
bekommen eine Host-Komposition mit eigenem Benutzer und `dotfiles.repoRoot`;
aktuell ist nur devbox-01 definiert. Alte Konfiguration: Branch `playground`.
Lokale Notizen (`docs/`) und Testskripte (`.local/`) werden nicht versioniert.

## Navigation und Themes

Neovim: `<Leertaste>n` schaltet nvim-tree links ein/aus und zeigt die aktuelle
Datei. Im Baum öffnet Enter Dateien/Ordner,
`a` legt an, `r` benennt um, `R` aktualisiert, `g?` zeigt die Tastenbelegung.
Der Baum übernimmt wieder die Git-Anzeige aus der alten Konfiguration.
`-` oder `<Leertaste>e` öffnet Oil im aktuellen Fenster: Enter öffnet einen
Eintrag, `-` geht nach oben, `g?` zeigt Hilfe. Dateinamen wie Text bearbeiten;
`:w` wendet die Dateioperationen nach Bestätigung an.
Strg+N/P wechselt im Normalmodus native Tabs (Fensterlayouts), `<Leertaste>tn`
legt einen Tab an, `<Leertaste>tc` schließt ihn. Buffer sind tabübergreifend.
`<Leertaste>g` öffnet Neogit, `bn`/`bp` nach Leertaste wechseln Buffer,
`ff` sucht Dateien, `fg` Projekttext, `fb` offene Buffer und `fh` zuletzt
geöffnete Dateien über Telescope. Strg+J/K bewegt die Auswahl, Enter öffnet im
aktuellen Fenster und Strg+T im neuen Tab,
Esc schließt. `fF` sucht auch ignorierte Dateien, `fs` Dokumentsymbole und
`<Leertaste>?` durchsucht die Tastenkürzel. Die Suche startet im Arbeitsverzeichnis und beachtet Git-Ignores.
Die obere Bufferline zeigt offene Dateien; `<Leertaste>` Tab/Shift-Tab wechselt
zwischen ihnen, `<Leertaste>q` schließt den Buffer und erhält das Fenster.
`tt`/`tf`/`tl` nach Leertaste führen nächsten Test, Datei oder letzten Test aus;
`tx` schließt das Test-Pane. `gd`/`gi`/`gr` springen zu Definitionen,
Implementierungen und Referenzen, `<Leertaste>rn` benennt Symbole um.
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

## Globale npm-Werkzeuge

Node/npm kommen aus Nix. Die native `config/npm/npmrc` wird als `~/.npmrc`
verlinkt: globale Pakete liegen unter `~/.local/share/npm`, ihr `bin/` liegt im
PATH; Cache und npm-Logs liegen unter `~/.cache/npm`. Diese Daten bleiben
außerhalb des Repositories und werden nicht durch Home Manager zurückgerollt.
Codex wird unabhängig vom Flake installiert und aktualisiert:

```sh
npm install -g @openai/codex@latest
```
