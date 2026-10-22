# Neovim

Das Feature übernimmt die Bedienung aus dem Legacy-Checkout `playground`
(`44ab6f2`). Nix installiert Neovim, Plugins, ausgewählte Treesitter-Parser und
Sprachserver. Die interaktive Konfiguration liegt als native Lua unter
`modules/features/neovim/config` und wird direkt nach `~/.config/nvim`
verknüpft. Nach Lua-Änderungen Neovim neu öffnen; ein Rebuild ist nur für die
Paket-/Plugin-Auswahl erforderlich. Kein zusätzlicher Pluginmanager, keine
automatischen Parser-/Mason-Downloads beim Editorstart.

## Aktivieren

```bash
dotfiles-rebuild
nvim
```

Neue Shells übernehmen auch `EDITOR`/`VISUAL=nvim`. Bestehende Shells können
vorübergehend `export EDITOR=nvim VISUAL=nvim` verwenden. Eine fremde
`~/.config/nvim` vorher sichern; Home Manager überschreibt sie nicht still.

Danach in einem echten Projekt eine PHP-/Blade-Datei öffnen,
`:checkhealth vim.lsp`, Completion und `gd` prüfen sowie einen Test über
`<Space>tn` starten. Dieser interaktive Test steht noch aus.

## Bedienung

Leader bleibt die Leertaste. Catppuccin Mocha, Dateibaum, Bufferleiste,
Statuszeile, relative Zeilennummern, System-Clipboard, Backups und persistentes
Undo bleiben erhalten. Sicherungs-/Swap-/Undo-Dateien liegen unter
`stdpath('state')`, nicht im Projekt.

| Tasten | Funktion |
| --- | --- |
| `<Space>ff`, `<Space>fF` | Dateien suchen, einschließlich ignorierter Dateien |
| `<Space>fg` | Projektsuche, im Visual-Modus nach Auswahl |
| `<Space>fb`, `<Space>fh`, `<Space>fs` | Buffer, Dateihistorie, Symbole |
| `<Space>n` | Dateibaum an der aktuellen Datei öffnen/schließen |
| `<Space><Tab>`, `<Space><S-Tab>`, `Ctrl-n/p` | Nächster/vorheriger Buffer |
| `mn`, `mp`, `<Space>^`, `<Space>$` | Buffer umordnen bzw. ersten/letzten wählen |
| `<Space>br`, `<Space>bl`, `<Space>bo` | Buffer rechts/links/alle anderen schließen |
| `<Space>q` | Buffer schließen, Fensteraufteilung erhalten |
| `Ctrl-h/j/k/l` | Neovim-Splits, am Rand weiter in herdr |
| `Alt-j/k` | Zeilen/Visual-Auswahl verschieben |
| `gd`, `gi`, `gr`, `K` | Definition, Implementierung, Referenzen, Dokumentation |
| `<Space>rn`, `<Space>ca`, `<Space>d`, `[d`, `]d` | Umbenennen, Codeaktion, Diagnosen |
| `Tab`, `Shift-Tab`, `Enter` im Insert-Modus | Completion/Snippets navigieren und bestätigen |
| `Ctrl-Space`, `Ctrl-e` im Insert-Modus | Completion öffnen/abbrechen |
| `gc`, `gcc` | Kommentar umschalten (Neovim-Builtin) |
| `if`, `af`, `ia`, `aa` | Funktions-/Parameter-Textobjekte |
| `v<Enter>`, dann `Tab`/`Shift-Tab` | Syntaxauswahl erweitern/verkleinern |
| `gJ`, `gS` | Syntaxelemente zusammenführen/aufteilen |
| `<Space>g`, `[c`, `]c`, `<Space>h…` | Neogit und Gitsigns-Hunks |
| `<Space>tn`, `<Space>tf`, `<Space>tl`, `<Space>tc` | Nächsten Test/Datei/letzten Test starten, herdr-Testpane schließen |

Der herdr-Test-Runner wird im aktuellen Tab mit Label `tests` wiederverwendet.
Außerhalb von herdr verwendet vim-test ein Neovim-Terminal. Projektbefehle und
Testabhängigkeiten kommen aus dem jeweiligen Projekt/devShell.

## Sprachserver und Laravel

Installiert sind Intelephense, der **offizielle** `laravel/lsp` (0.0.32),
TypeScript-LSP samt TypeScript, Tailwind CSS, Pyright, Lua-LSP und nil für Nix.
Dart, SourceKit und ZLS werden nur aktiviert, wenn das jeweilige SDK/Programm
im PATH vorhanden ist; große SDKs werden nicht global installiert.
Projekt-devShells können andere Toolversionen bereitstellen: Die zusätzlichen
Editor-Werkzeuge werden an PATH angehängt. Node-/Ruby-/Python-Provider bleiben
aus, da diese Lua-/Vimscript-Plugins sie nicht benötigen. Die entsprechenden
Sprachserver funktionieren trotzdem.

Intelephense bearbeitet PHP. Laravel-LSP ergänzt Laravel-spezifische
Vervollständigung, Navigation und Diagnosen nur in Projekten mit `artisan`.
`*.blade.php` erhält den Dateityp `blade`; dort startet Laravel-LSP,
Intelephense wird nicht auf das Template angesetzt. Die Server behalten ihre
Funktionen; Überschneidungen bei echten Projekten lassen sich bei Bedarf über
die offiziellen Laravel-Featureoptionen abstimmen. Kein Intelephense-
Lizenzschlüssel ist hinterlegt.

Das offizielle Release-PHAR ist mit Version und SHA-256 über ein kleines
Nix-Paket fixiert und startet mit Nix-PHP. Das PHP zur Analyse der Anwendung
ermittelt Laravel-LSP aus der Projektumgebung. Projektabhängigkeiten müssen
vorhanden sein; der Editor installiert sie nicht. `pestGenerateDocBlocks=false`
verhindert automatisch erzeugte Pest-Hilfsdateien beim Öffnen.

Quellen: [Laravel-LSP](https://github.com/laravel/lsp),
[Neovim-LSP](https://neovim.io/doc/user/lsp.html).

## Große Dateien

Die vorherigen Verzögerungen wurden nicht reproduziert oder einem einzelnen
Plugin nachgewiesen. Folgende vermeidbare Mehrarbeit wurde trotzdem entfernt:

- Kein zusätzliches Vim-Regex-Highlighting neben Treesitter.
- Buffer-Wort-Completion nur aus dem aktuellen Buffer unter 256 KiB, ab drei
  Zeichen. Andere geöffnete Logs werden nicht zusätzlich durchsucht.
- Keine automatische Treesitter-Scope-Berechnung durch Einrückungslinien.
- Lualine verwendet die vorhandenen Gitsigns-Diffdaten.
- Telescope begrenzt Dateivorschauen auf 1 MiB und verwendet dafür kein Treesitter.
- Dateibaum-Watcher ignorieren Dependency-/Build-Verzeichnisse wie `vendor`,
  `node_modules` und `.direnv`. Diese bleiben sichtbar; manuell mit `R`
  aktualisieren, falls nötig.

Ab **1 MiB**, **20.000 Zeilen** oder einer Zeile mit mindestens **4.000 Bytes**
setzt der Editor einen Großdatei-Modus: kein LSP, Treesitter, Syntaxhighlighting,
Gitsigns, Einrückungslinien, Spellcheck oder automatische Completion.
Bearbeiten, Speichern, Suche und Undo bleiben verfügbar. Die Erkennung greift
auch beim Wachsen eines Buffers und bleibt bis zu dessen Schließen aktiv.
Schwellen: `config/lua/dotfiles/large-files.lua`.

## Bereinigte Altlasten

| Entfallen | Ersatz/Grund |
| --- | --- |
| vim-commentary | Eingebaute `gc`-/`gcc`-Kommentare |
| vim-highlightedyank | `vim.hl.on_yank` |
| vim-lastplace | Autocommand für die letzte Cursorposition |
| vim-rooter | Einmalige Projektwurzel-Erkennung über `vim.fs.root` |
| vim-tmux-navigator und vimux | Direkte herdr-Integration, Terminal-Fallback; kein tmux-Fallback mehr |
| cmp-ai-Reste | Plugin war schon deaktiviert; KI-Workflows folgen separat |
| nvim-ts-context-commentstring | War nicht eingerichtet; native Kommentare nutzen Syntaxinformationen |
| Alle Treesitter-Grammatiken | Gezielte Liste für bisherige Sprachen und gängige Projektdateien |

Treesitter/Textobjekte verwenden die neue API statt des abgekündigten Legacy-
Zweigs. Inkrementelle Auswahl nutzt Neovims Node-API. `<Space>td` verwendet die
aktuelle Inline-Hunk-Vorschau statt des entfernten `toggle_deleted`.
`<Space>x` nutzt `vim.ui.open`, auch bei Leerzeichen im Pfad und auf macOS.

## Prüfstand

NixOS-Toplevel und Home-Manager-Generation gebaut, nicht aktiviert.
Headless-Tests unter `modules/features/neovim/tests` prüfen in temporären
XDG-Verzeichnissen Start, Highlighting/Completion, Syntaxauswahl, Splitwechsel
und den herdr-Aufruf am Fensterrand über einen Test-Double sowie große und
minifizierte Dateien. Der LSP-Test startet echte Intelephense-/Laravel-Prozesse,
prüft Initialisierung und Blade-Zuordnung. Ein echter Laravel-Workspace und
der herdr-Test-Runner sind nach Aktivierung noch interaktiv zu prüfen.
macOS/ARM wurden nicht auf Hardware getestet.

Nach Aktivierung im Repository:

```bash
nvim --headless -c 'luafile modules/features/neovim/tests/smoke.lua' '+qa!'
nvim --headless -c 'luafile modules/features/neovim/tests/lsp.lua' '+qa!'
```

Die Tests erstellen und entfernen eigene temporäre Dateien. Für getrennte
Editor-Caches zusätzlich temporäre XDG-Verzeichnisse verwenden. Konkrete
Verzögerungen anschließend mit reproduzierbarem Ablauf untersuchen;
`nvim --startuptime /tmp/nvim-startup.log datei` misst nur Startzeit, nicht die
Reaktion beim Tippen oder Scrollen.
