# Projektumgebungen mit Flakes

Die persönliche Umgebung stellt direnv samt nix-direnv und die Anbindung an
zsh/Bash bereit. Jedes Projekt beschreibt seine Werkzeuge dagegen selbst in
`flake.nix` und fixiert sie mit einem eigenen `flake.lock`. Ein Projekt kann
dadurch seine Pakete unabhängig vom Betriebssystem und von anderen Projekten
aktualisieren. Es benötigt weder dieses Dotfiles-Repo noch Home Manager.

Wir beginnen mit `pkgs.mkShellNoCC` und einem Nixpkgs-Input. Zusätzliche
Frameworks und automatisch gestartete Dienste sind dafür nicht erforderlich.
Native Manifeste wie `package.json`, `pyproject.toml` oder `composer.json`
bleiben für die Anwendung und ihre Bibliotheken zuständig; die Flake liefert
zum Beispiel die passende Node-/Python-/PHP-Laufzeit und Systemwerkzeuge.
Projekt-devShells sind keine Container und isolieren keine Systemdienste.

## Dieses Repository

Die erste konkrete devShell ist die des Dotfiles-Repos: Sie enthält `nixfmt`
und `shellcheck` aus dessen bestehendem, fixiertem Nixpkgs-Input.

```bash
cd "$DOTFILES"
nix develop
# In der devShell, standardmäßig Bash:
nixfmt --check modules/features/development.nix
shellcheck scripts/t scripts/wt modules/features/herdr/plugins/vim-nav/navigate.sh
exit

# Alternativ einen einzelnen Befehl ausführen:
nix develop --command shellcheck scripts/rebuild scripts/t scripts/wt
```

`nix develop --command zsh` startet die vorhandene zsh mit der Projektumgebung.
Beim normalen `nix develop` ist Bash das Standardverhalten von Nix.

Für automatisches Laden einmal `dotfiles-rebuild` ausführen und ein neues
Terminal öffnen, damit der direnv-Hook geladen wird. Danach:

```bash
cd "$DOTFILES"
direnv allow
```

Die eingecheckte `.envrc` enthält nur `use flake`. direnv lädt die Umgebung
beim Betreten in die bestehende Shell und entfernt deren Änderungen beim
Verlassen. Es wechselt dabei weder Shell noch Prompt. nix-direnv hält die
Umgebung im Cache; `.direnv/` bleibt aus Git ausgeschlossen.

Jede `.envrc` wird vor dem ersten Laden ausdrücklich freigegeben. Änderungen
an ihr benötigen erneut `direnv allow`; es gibt keine pauschale Freigabe für
`~/code`. `direnv deny` entzieht die Freigabe. Ohne direnv funktioniert
`nix develop` weiterhin.

Die Vorlage liefert eine `.gitignore` mit `/.direnv/` mit. Bei vorhandenen
Projekten diesen Eintrag in die bestehende Datei übernehmen. `.gitignore`
betrifft nur Git; sie schützt keine Dateien vor Löschbefehlen.

`rm -rf -- .direnv` im Projekt entfernt den lokalen Cache samt seinen
Verknüpfungen, ohne deren Ziele im `/nix/store` zu löschen. Der Cache wird beim
nächsten Laden neu erzeugt. Um das automatische Laden zu stoppen, stattdessen
`direnv deny` verwenden. Auch das vollständige Projektverzeichnis lässt sich
normal löschen; seine `.direnv`-Verknüpfungen löschen keine gemeinsam genutzten
Nix-Pakete. Nicht mehr referenzierte Store-Pfade bereinigt später Nix-GC.

## Ein neues Projekt beginnen

In einem leeren Projektverzeichnis:

```bash
git init
nix flake init --template "$DOTFILES#default"
git add flake.nix .envrc .gitignore README.md
nix flake lock
git add flake.lock
nix develop
```

Die Vorlage wird kopiert und gehört anschließend dem Projekt. Spätere
Dotfiles-Änderungen verändern bestehende Projekte nicht. In einem bestehenden
Projekt vorhandene Dateien zuerst vergleichen und die benötigten Teile
zusammenführen; insbesondere `README.md` und `.gitignore` nicht ersetzen.

Unter `packages` stehen die Werkzeuge, zum Beispiel:

```nix
packages = [
  pkgs.nodejs_24
  # Oder passend zum Projekt: pkgs.python3, pkgs.uv, pkgs.php, …
];
```

Die Basisvorlage enthält zunächst nur Git und definiert Ausgaben für
x86_64/aarch64 auf Linux und macOS. Zusätzliche Pakete müssen auf den jeweils
gewünschten Plattformen verfügbar sein. Andere Plattformen werden durch die
Ausgabe allein noch nicht praktisch getestet.

Der `systems`-Block zählt unterstützte Plattformen auf; er installiert keine
weiteren Betriebssysteme und baut bei `nix develop` nur die lokale Ausgabe.
Für ein reines ThinkPad-Projekt reicht `systems = [ "x86_64-linux" ];`.
Die vier Einträge halten die Vorlage auch für Linux auf ARM und Macs nutzbar.

In einem Git-Repository berücksichtigt Nix neue Dateien erst, wenn sie mit
`git add` erfasst wurden; ein Commit ist zum Ausprobieren nicht nötig.
`flake.lock` wird eingecheckt, `.direnv/` nicht. Wer die Automatik möchte,
führt nach Prüfung der `.envrc` auch hier einmal `direnv allow` aus.

## Ändern und aktualisieren

Werkzeuge in der Projekt-Flake ändern, dann `nix develop` oder `direnv reload`
verwenden. Dafür ist kein NixOS-Rebuild erforderlich. Ein Rebuild betrifft nur
die Einrichtung der globalen direnv-/Shell-Anbindung.

```bash
# Im jeweiligen Projekt, nur auf dessen Lockfile bezogen:
nix flake update nixpkgs
nix develop --command git --version
git diff -- flake.lock
```

Bei Fehlern auf direnv-Meldungen achten: nix-direnv kann die letzte gültige
Umgebung als Fallback behalten. `nix develop` zeigt den Fehler der aktuellen
Flake direkt. Es gibt hier keine automatischen Input-Updates und keine
automatische Installation von npm-/Python-/Composer-Abhängigkeiten.

Als nächster Ausbau folgt eine passende Laufzeit in einem echten
Anwendungsprojekt. Worktree-Bootstrap, Testdatenbanken und KI-Workflows bleiben
separate Aufgaben. Bei Worktrees hat jeder Checkout seine eigene
Projektumgebung und direnv-Freigabe.

Referenz: [nix-direnv: Einrichtung und Flake-Nutzung](https://github.com/nix-community/nix-direnv#flakes-support).

Prüfstand vom 2026-10-19: NixOS-Toplevel ausgewertet, Flake-Checks und
Systembuild erfolgreich; Dotfiles-devShell sowie eine aus der Vorlage erzeugte
Umgebung unter x86_64-linux ausgeführt. direnv-Freigabe, Laden und Entladen
isoliert unter `/tmp` getestet. Die drei übrigen Plattform-Ausgaben wurden
ausgewertet, aber nicht gebaut oder auf entsprechender Hardware getestet.
Die Systemänderung wurde dabei nicht aktiviert.
