# Generationen und Speicherbereinigung

Das NixOS-Feature `generation-cleanup` installiert `nixos-generations` und
einen wöchentlichen Timer. Der ThinkPad wählt es ausdrücklich aus. Der
Python-Helfer und seine Tests liegen neben dem Modul unter
`modules/features/generation-cleanup/`; Änderungen benötigen einen Rebuild.

## Aufbewahrung

Die Auswahl ist die Vereinigung dieser Regeln:

| Regel | Behalten |
| --- | --- |
| Neueste Generationen nach Generationsnummer | 5 |
| Heute und zwei vorherige Kalendertage | Neueste Generation je Tag |
| Aktuelle und drei vorherige Kalenderwochen, ab Montag | Neueste Generation je Woche |
| Aktueller und zwei vorherige Kalendermonate | Neueste Generation je Monat |

Überlappungen zählen einmal. Es bleiben höchstens 15 reguläre Generationen,
in der Praxis meist weniger. Fehlende Zeiträume werden nicht mit älteren
Ständen aufgefüllt. Zusätzlich geschützt sind alle Generationen, die auf
eines dieser Systeme verweisen:

- Laufendes System: `/run/current-system`.
- Zuletzt gebootetes System: `/run/booted-system`.
- Ausgewähltes Systemprofil/Boot-Ziel: `/nix/var/nix/profiles/system`.
- Markierter bewährter Stand: `/nix/var/nix/gcroots/dotfiles-known-good`.

Zeitstempel in der Zukunft verhindern vorsichtshalber ebenfalls das Löschen.

## Aktivieren und prüfen

```bash
dotfiles-rebuild
nixos-generations preview
```

Ohne Unterbefehl erscheint ebenfalls nur eine Vorschau. Sie benötigt kein
sudo und zeigt für jede Generation die Gründe zum Behalten oder Löschen.
Profile, Bootmenü und Store bleiben dabei unverändert.

Vor dem ersten Bereinigen einen tatsächlich erprobten Stand markieren:

```bash
# Standard: zuletzt gebootete Generation, auch nach mehreren Rebuilds.
sudo nixos-generations pin

# Alternativ ausdrücklich eine vorhandene Nummer aus der Vorschau wählen:
sudo nixos-generations pin 18

nixos-generations preview
```

`pin` ersetzt die einzelne bisherige Markierung. Die Verknüpfung ist zugleich
eine GC-Root und schützt den Systempfad vor regulärer Garbage Collection.
Unsere Bereinigung behält auch die passende Generation für das Bootmenü.
Wurde deren Profillink anderweitig gelöscht, bricht `apply` ab, bis wieder ein
vorhandener Stand markiert ist.

```bash
sudo nixos-generations apply
```

Die Bereinigung führt in dieser Reihenfolge aus:

1. Auswahl berechnen und Schutzstände prüfen.
2. Nur die ausgewählten NixOS-Systemgenerationen über
   `nix-env --profile /nix/var/nix/profiles/system --delete-generations NUMMERN`
   entfernen.
3. Mit `switch-to-configuration boot` aus dem ausgewählten Systemprofil das
   Bootmenü aktualisieren. Das wechselt keine laufenden Dienste und erzeugt
   keine neue Generation. Auch ein mit `nixos-rebuild boot` gewähltes Ziel
   wird berücksichtigt.
4. Erst danach `nix-store --gc` ausführen.

Fehlschläge beim Löschen oder Aktualisieren des Bootmenüs verhindern die GC.
Profillinks können dann bereits entfernt sein; die Store-Pfade wurden durch
diesen Lauf noch nicht bereinigt. Fehler beheben und erneut ausführen. Auch
ohne weitere Löschkandidaten werden Bootmenü und Garbage Collection ausgeführt.

## Automatik und Rebuilds

```bash
systemctl list-timers nixos-generation-cleanup.timer
journalctl -u nixos-generation-cleanup.service
```

Der Timer läuft wöchentlich mit bis zu einer Stunde Zufallsverzögerung und
holt verpasste Termine nach. Ohne Markierung überspringt er die Bereinigung;
ein manueller `apply` verweigert sie. Nach dem Markieren kann der nächste
Timerlauf selbständig löschen, einschließlich eines nachgeholten Termins.
Ein Rebuild startet die Bereinigung nicht als Aktivierungsaktion.

`scripts/rebuild` und die Bereinigung verwenden dieselbe Sperre
`/run/lock/dotfiles-system.lock`. So warten sie aufeinander. Direkte Rebuilds,
Rollbacks und andere administrative Profiländerungen während `apply` vermeiden
oder ebenfalls mit diesem Lock ausführen, zum Beispiel:

```bash
sudo flock /run/lock/dotfiles-system.lock nixos-rebuild boot --flake "$DOTFILES"
```

Der Helfer prüft zusätzlich die Profildaten vor dem Löschen und die
Schutzpfade vor und nach der Bootmenü-Aktualisierung. Erkannte Änderungen
führen zum Abbruch. Diese Prüfungen ersetzen keine gemeinsame Sperre für
andere administrative Befehle.

Das Feature setzt systemd-boot ohne weiteres Generationenlimit voraus: Alle
erhaltenen Stände sollen im Bootmenü verfügbar bleiben. Eine zweite
automatische `nix.gc`-Löschregel darf nicht parallel aktiviert sein.

## Grenzen und Tests

Die Staffel begrenzt die Zahl regulärer Systemgenerationen, nicht ihre
Speichergröße. Generationen teilen Store-Pfade; zusätzliche Profile,
devShell-Caches und andere GC-Roots können Pakete weiter festhalten.
Benutzer-/Home-Manager-Generationen werden hier nicht ausgedünnt.

Ein System-Rollback setzt die direkt ins Checkout verknüpften nativen
Konfigurationsdateien nicht zurück; dafür dient Git. Wichtige Daten benötigen
ein eigenes Backup. Andere manuelle Löschbefehle können die Aufbewahrung
umgehen, etwa indem sie geschützte Profillinks entfernen.

Die Flake-Checks testen Auswahl, Kalendergrenzen, Schutzstände und
Fehlerreihenfolge an Wegwerfprofilen. Auf dem echten System wurde beim
Entwickeln ausschließlich `preview` verwendet; nichts aktiviert oder gelöscht.
