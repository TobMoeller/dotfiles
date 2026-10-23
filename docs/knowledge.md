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
die Dotfiles installieren nur Obsidian. Es gibt keinen automatischen Git-Sync.

Für Agents später nach Bedarf `project-log/<projekt>/context.md`, `status.md`
und `sessions/` anlegen. Langlebige Erkenntnisse wandern ins brain. Die alten
Agent-Workflows werden dadurch noch nicht aktiviert.
