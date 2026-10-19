# herdr

herdr kommt aus dem fixierten Tools-Input. Home Manager installiert außerdem
fzf, jq und unter Linux wl-clipboard. Die native Konfiguration liegt unter
`modules/features/herdr/config.toml` und ist direkt als
`~/.config/herdr/config.toml` verknüpft. Der lokale vim-nav-Helfer liegt daneben
unter `plugins/vim-nav`; die Aktivierung registriert ihn über `herdr plugin link`.
Andere Plugin-Registrierungen bleiben erhalten.

## Start und Bedienung

Nach `dotfiles-rebuild` startet `herdr` die Standardsitzung oder verbindet sich
erneut damit. Es gibt kein automatisches Attach beim Terminalstart. Mit
`herdr --session name` öffnet man eine benannte Sitzung.

Das Präfix ist **Strg+Y**: drücken, loslassen, dann die folgende Taste drücken.

| Taste nach Strg+Y | Aktion |
| --- | --- |
| `?` | Aktive Tastenkürzel anzeigen |
| `d` | Sitzung verlassen; Prozesse laufen weiter |
| `c` | Neuer Tab |
| `n` / `p` | Nächster / vorheriger Tab |
| `v` / `-` | Pane rechts / unten aufteilen |
| `h` / `j` / `k` / `l` | Pane links / unten / oben / rechts fokussieren |
| `z` | Aktuellen Pane vergrößern / zurücksetzen |
| `x` | Pane schließen |
| `w` | Workspace-Auswahl |
| `f` | Projekt-Auswahl im Popup |
| `Umschalt+A` | Worktree anlegen |
| `Umschalt+W` | Vorhandenen Worktree öffnen |
| `Umschalt+K` | Worktree mit Bestätigung entfernen |
| `Umschalt+R` | Konfiguration neu laden |

Direkt funktionieren **Alt+J/K** für nächsten/vorherigen Workspace und
**Alt+H/L** für vorherigen/nächsten Agenten. Im Navigationsmodus wählen `j/k`
Workspaces, die Pfeiltasten links/rechts Panes.

Wie in playground gehen **Strg+H/J/K/L** über den vim-nav-Helfer: Bei Vim,
Neovim oder fzf im Vordergrund sendet er die Taste an das Programm; sonst
wechselt er den herdr-Pane. Dadurch stehen diese Tasten innerhalb herdr
anderen Shell-Funktionen nicht zur Verfügung, insbesondere Strg+K und Strg+L.
Wer diese Shell-Shortcuts erhalten möchte, entfernt die vier entsprechenden
`[[keys.command]]`-Blöcke und nutzt die Pane-Tasten mit Präfix.

Der Neovim-Teil folgt bei dessen Überführung: Weiterreichen allein richtet
dort noch keine Split-Navigation und keinen Wechsel über den Fensterrand ein.

## Projekte und Worktrees

`t` ohne Argument sucht Git-Checkouts unter `~/code` und zeigt sie mit fzf an.
Die Suchtiefe deckt `~/code/brain`, `~/code/owner/repo` und
`~/code/worktrees/repo/branch` ab. `.git`-Dateien verknüpfter Worktrees werden
ebenfalls erkannt. Mit `t /pfad/zum/projekt` öffnet man ein Verzeichnis direkt;
es muss kein Git-Repository sein. Pfade mit Leerzeichen sind unterstützt.

Innerhalb herdr öffnet `t` einen Workspace in der aktuellen Sitzung oder
fokussiert einen vorhandenen Pane mit diesem Startverzeichnis. Außerhalb herdr
öffnet es eine dauerhafte, nach Projekt benannte Sitzung. Ein Prüfsummen-Suffix
aus dem absoluten Pfad unterscheidet gleichnamige Projektverzeichnisse.

`wt` ist ein kurzer Alias als Script für `herdr worktree`:

```bash
wt list
wt create --branch feature/example
wt open --path /pfad/zum/worktree
wt --help
```

Diese Befehle in der passenden herdr-Sitzung ausführen. Neue Worktrees liegen
standardmäßig unter `~/code/worktrees`. Die eingebauten Menüs öffnen und
gruppieren sie als Workspaces. Schließen eines Workspace löscht den Checkout
nicht. Zum Entfernen vorzugsweise Strg+Y, Umschalt+K verwenden: Die Oberfläche
fragt vor dem Löschen nach. `wt remove` ist dagegen ein direkter CLI-Befehl.
Das alte Script mit projektspezifischen Docker-/Dateikopier-Aktionen wird
nicht übernommen; solche Schritte gehören später in das jeweilige Projekt.

Abgleich mit dem aktualisierten Legacy-Stand `playground` (`44ab6f2`):
Tasten, vim-nav und Statussymbole sind berücksichtigt. Dessen erweiterte
`wt`-Befehle `add`, `rm`, `ls`, `main`, `back`, `agent`, `lead` und `testdb`
werden hier nicht nachgebildet. Der neue Helfer reicht die nativen Unterbefehle
`create`, `open`, `list` und `remove` weiter. Worktree-Bootstrap,
Bereitschaftsmarker, Agentensteuerung und Testdatenbank-Abläufe bleiben
Migrationsthemen für Dev-Umgebungen und Skills; die bisherige Pipeline ist mit
diesem Helfer noch nicht lauffähig.

## Änderungen und Updates

Nach nativen Änderungen:

```bash
herdr config check
herdr server reload-config
```

In einer laufenden Oberfläche lädt Strg+Y, Umschalt+R auch deren lokale
Einstellungen neu. Bei benannten Sitzungen außerhalb herdr explizit
`herdr --session name server reload-config` verwenden. Neue Pakete,
Symlinks und die Plugin-Registrierung benötigen dagegen `dotfiles-rebuild`.

herdrs ausführbare Datei wird über Nix aktualisiert; dafür keinen eingebauten
Updater verwenden. Die automatische Versionsabfrage ist deaktiviert.
Native Checkout-Dateien folgen Git statt NixOS-Generations-Rollbacks.

Referenzen: [Konfiguration](https://herdr.dev/docs/configuration/) und die
Versionshilfe `herdr --default-config`, `herdr worktree --help`.
