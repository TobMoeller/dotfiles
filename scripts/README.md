# Repository-Scripts

Scripts halten wiederkehrende Befehle lesbar fest. `DOTFILES` zeigt auf das Repository und wird von Home Manager aus `dotfiles.repositoryPath` gesetzt. Weitere Helfer übernehmen wir gezielt aus dem alten Repository, wenn die entsprechende Umgebung eingerichtet ist.

## rebuild

```bash
"$DOTFILES/scripts/rebuild"
# Auf dem ThinkPad nach Aktivierung auch direkt:
dotfiles-rebuild
```

Das Script wechselt mit `cd "$DOTFILES"` ins Repository und führt genau diesen Befehl aus:

```bash
sudo flock /run/lock/dotfiles-system.lock nixos-rebuild switch --flake .
```

`nixos-rebuild` selbst wählt anhand des laufenden Hostnamens die Konfiguration aus. Das Script hat keine eigene Argumentverarbeitung. `switch` baut, aktiviert und setzt die Generation als Boot-Standard.

`flock` teilt eine Sperre mit der Generationenbereinigung, damit Rebuild und
Bereinigung nicht gleichzeitig Profile oder Bootmenü verändern. Details und
der Vorschau-Befehl stehen unter [Generationen](../docs/generations.md).

Andere Abläufe lassen sich direkt aus dem Repository ausführen:

```bash
nixos-rebuild build --flake .                 # Nur bauen
sudo nixos-rebuild dry-activate --flake .     # Geplante Änderungen anzeigen
sudo nixos-rebuild switch --flake .#NEUER-NAME # Einmalig bei einer Umbenennung
```

Das Script setzt voraus, dass Flakes aktiviert sind und `DOTFILES` gesetzt ist, und unterstützt zunächst NixOS. Nach der ersten Aktivierung der Variablen einmal ab- und wieder anmelden. In einer bereits laufenden Shell kann man vorab `export DOTFILES="$HOME/code/tobmoeller/dotfiles"` ausführen.

## PATH und eigene Befehle

Home Manager nimmt `~/.local/bin` in den persönlichen PATH auf. npm verwendet über `NPM_CONFIG_PREFIX` den Prefix `~/.local`: Pakete liegen unter `~/.local/lib/node_modules`, ihre Befehle unter `~/.local/bin`. Die bestehende `.npmrc` bleibt erhalten; die Umgebungsvariable legt den Prefix auch auf frisch eingerichteten Geräten fest.

Eigene Repo-Scripts werden gezielt als Symlinks in `~/.local/bin` bereitgestellt. Es gibt keine Kopien und keinen Sync-Schritt; Änderungen an der Quelldatei gelten unmittelbar. Auf dem ThinkPad verknüpft Home Manager `dotfiles-rebuild` mit `$DOTFILES/scripts/rebuild`. Dieser NixOS-Helfer wird im Hostmodul ausgewählt.

## init-knowledge

`dotfiles-init-knowledge TobMoeller` klont `brain` und `project-log` unter
`~/code/knowledge`. Vor Aktivierung: `./scripts/init-knowledge TobMoeller`.
Bestehende Checkouts bleiben unangetastet. Pfade kommen aus `BRAIN` und
`PROJECT_LOG`, der GitHub-Owner aus dem Argument. Details: [Wissensrepos](../docs/knowledge.md).

## t und wt

Das herdr-Feature verknüpft beide Scripts in `~/.local/bin`:

- `t`: Git-Projekt unter `~/code` mit fzf auswählen; alternativ `t /pfad`.
  In herdr einen Workspace öffnen/wiederfinden, außerhalb eine Projektsitzung starten.
- `wt`: Argumente direkt an `herdr worktree` weiterreichen, z. B.
  `wt create --branch feature/example` oder `wt list`.

Tasten, Worktree-Menüs und Unterschiede zwischen Sitzungen und Workspaces
stehen in [der herdr-Anleitung](../docs/herdr.md).
