# brain und project-log

`brain` enthält dauerhafte Notizen und wird als bestehender Ordner in Obsidian
geöffnet. `project-log` hält Arbeitsstände und Kontext für Agents getrennt davon.
Beide sind eigene Repositories unter `~/code/knowledge`.

```bash
dotfiles-rebuild
dotfiles-init-knowledge TobMoeller
```

Vor dem Rebuild geht auch `./scripts/init-knowledge TobMoeller`.
Der Befehl klont `brain` und `project-log` über SSH. Vorhandene Checkouts bleiben
unverändert, andere vorhandene Verzeichnisse werden nicht überschrieben.
Ein leeres GitHub-Repository ist erlaubt; es werden keine Inhalte erzeugt,
Commits erstellt oder Änderungen gepusht. Der SSH-Schlüssel muss entsperrt sein.

Neue Shells erhalten `BRAIN=~/code/knowledge/brain` und
`PROJECT_LOG=~/code/knowledge/project-log`. `WORK_LOG` zeigt als Kompatibilität
für spätere alte Helfer auf denselben Ort. BRAIN/PROJECT_LOG lassen sich für
einen Init-Aufruf überschreiben; hostbezogene Vorgaben stehen in Home Manager.

In Obsidian **Ordner als Vault öffnen** wählen und `brain` auswählen. Profile,
Plugins und Vault-Einstellungen bleiben im Wissensrepo beziehungsweise lokal;
die Dotfiles installieren Obsidian. Es gibt keinen automatischen Git-Sync.

## Syncthing

Nach `dotfiles-rebuild` im Launcher **Syncthing Web UI** öffnen oder
`http://127.0.0.1:8384` aufrufen. Der Dienst läuft als Benutzer; Geräte und
Freigaben werden in der Weboberfläche verwaltet und bleiben bei Rebuilds erhalten.
Die Weboberfläche ist nur lokal erreichbar; die Firewall erlaubt die üblichen
Synchronisations- und LAN-Erkennungsports. Schlüssel bleiben lokal.

Alle drei Geräte direkt miteinander koppeln und denselben brain-Ordner teilen.
Die vorhandene Ordner-ID übernehmen und hier `~/code/knowledge/brain` wählen.
Vor der ersten Synchronisation auf jedem Gerät unter **Ignorierte Muster** setzen:

```text
.git
.obsidian/workspace.json
.obsidian/workspace-mobile.json
```

Git-Repositories bleiben pro Gerät unabhängig. Vorerst Syncthing für den
Dateiaustausch nutzen und Git-Commits/-Pushes bewusst ausführen; keine zusätzliche
automatische Git-Pull-Synchronisation aktivieren. Bei Bedarf Ordner-Versionierung
aktivieren; sie ersetzt kein separates Backup. Einen automatisch angelegten
Standardordner nur bei Bedarf nutzen, brain separat hinzufügen.

Diagnose: `systemctl --user status syncthing` und
`journalctl --user -b -u syncthing`. Der praktische Gerätetest steht noch aus.

Für Agents später nach Bedarf `project-log/<projekt>/context.md`, `status.md`
und `sessions/` anlegen. Langlebige Erkenntnisse wandern ins brain. Die alten
Agent-Workflows werden dadurch noch nicht aktiviert.
