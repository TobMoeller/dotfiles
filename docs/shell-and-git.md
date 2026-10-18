# zsh und Git

Das gemeinsame Benutzerprofil wählt die Home-Manager-Features `zsh`, `starship` und `git`.
Der ThinkPad-Host aktiviert zusätzlich die NixOS-zsh-Integration und setzt
zsh als Login-Shell für `tobias`.

Nach `dotfiles-rebuild` lässt sich die aktuelle Shell mit `exec zsh` ersetzen.
Einmal vollständig ab- und anmelden aktualisiert auch die Login-Umgebung;
ein Neustart ist nicht erforderlich. Terminals sollten die Login-Shell verwenden.

Home Manager erzeugt die Startdateien unter `~/.config/zsh` und lädt die
Sitzungsvariablen einschließlich `DOTFILES`, npm-Prefix und PATH.
`~/.zshenv` lädt die dortige `.zshenv`, die `ZDOTDIR` auf `~/.config/zsh` setzt.
zsh liest deshalb `~/.config/zsh/.zshrc`; ohne `ZDOTDIR` ist `~/.zshrc` der
Standard. Eine fehlende `.zshrc` direkt im Home-Verzeichnis ist hier gewollt.
`~/.config/zsh/config.zsh` ist ein direkter Symlink auf
`modules/features/zsh/config.zsh`. Änderungen daran benötigen nur `exec zsh`.
Optionale lokale Ergänzungen können in `~/.config/zsh/local.zsh` stehen.

Enthalten sind Completion, geteilte History (50.000 Einträge), Vorschläge,
Syntaxhervorhebung und Starship als Prompt. `~/.config/starship.toml` ist direkt
mit `modules/features/starship/starship.toml` verknüpft; Änderungen erscheinen
beim nächsten Prompt. Home Manager übernimmt Installation und zsh-Integration.

Der Prompt zeigt Verzeichnis, Git-Branch/-Status und gegebenenfalls eine
Nix-Shell. Die Eingabe beginnt auf einer eigenen Zeile. Rechts stehen
Fehlercodes und die Befehlslaufzeit, auch für kurze Befehle mit Millisekunden.
Der Hostname erscheint bei SSH-Sitzungen. Ein grünes `>` kennzeichnet Erfolg,
ein rotes Fehler und ein gelbes `<` den Vi-Befehlsmodus. Es ist keine Nerd Font
erforderlich. Feintuning und Alternativen stehen in der Roadmap.
Die History ignoriert Befehle mit führendem Leerzeichen; sie ist kein sicherer
Aufbewahrungsort für Geheimnisse. Keine automatischen herdr-Sitzungen.

Die Tastaturbelegung nutzt den Vi-Modus wie die frühere Konfiguration:
Escape wechselt in den Befehlsmodus, `i` zurück zur Eingabe. Strg-P/Strg-N
navigieren durch die History, Strg-R durchsucht sie und Strg-F übernimmt am
Zeilenende einen Vorschlag. Anders als früher stammt der Vi-Modus zunächst
direkt aus zsh; das zusätzliche zsh-vi-mode-Plugin ist nicht übernommen. Aliase:
`ll`, `la`, `..`, `...` und `gs`.

Das Git-Feature enthält nur gemeinsame Einstellungen und die Aliase
`s`, `st`, `ci`, `co`. Neue Repositories verwenden `main`;
`push.autoSetupRemote` erleichtert den ersten Push neuer Branches.
Name und E-Mail stehen im Home-Manager-Teil des ThinkPad-Hosts. Ein Arbeitsgerät
kann dieselben Features mit seiner eigenen Identität importieren.

Die bereits lokal gesetzte Repository-Identität hat Vorrang vor der globalen
Konfiguration und stimmt hier mit der privaten Host-Identität überein.
Prüfen nach Aktivierung:

```bash
echo "$ZSH_VERSION"
command -v codex dotfiles-rebuild
git config --show-origin --get user.email
git config --global --get user.name
```

## GitHub über SSH

GitHub benötigt für diese Verbindung einen SSH-Schlüssel; ein Personal Access
Token gehört zum HTTPS-Zugriff. Private Schlüssel bleiben außerhalb des Repos.
Nach Hinterlegen des öffentlichen Schlüssels:

```bash
ssh -T git@github.com
```

GitHub bestätigt erfolgreiche Anmeldung mit einer Begrüßung, beendet den
Befehl aber mit Exit-Code 1, weil es keinen Shell-Zugriff anbietet.
Danach für dieses Repository:

```bash
git remote set-url origin git@github.com:TobMoeller/dotfiles.git
git push -u origin nixos-foundation
```

Der Push veröffentlicht den neuen Branch; `playground` und der Default-Branch
bleiben erhalten.

Der lokale Branch hieß zunächst `rebuild/nixos-foundation`. GitHub enthält
bereits `rebuild`, was diesen Namen wegen eines Datei-/Verzeichniskonflikts
verhindert. Deshalb wurde der lokale Branch in `nixos-foundation` umbenannt.
