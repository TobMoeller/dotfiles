# Swap und Hibernate auf dem ThinkPad

## Konfiguration

Das Hostmodul definiert `/swapfile` mit 81920 MiB (80 GiB). NixOS erstellt und formatiert diese Datei bei der ersten Aktivierung und aktiviert sie als Swap. Sie liegt auf dem bereits LUKS-verschlüsselten ext4-Root-Dateisystem. Es werden weder Partitionen geändert noch zusätzliche Zufallsschlüssel für Swap verwendet.

Das Feature `hibernate` schaltet systemd im Initrd ausdrücklich ein (hier bereits zuvor aktiv). Das System bootet über UEFI; Secure Boot ist bei der Bestandsaufnahme deaktiviert. systemd ermittelt beim Hibernate automatisch das Swap-Gerät und den Datei-Offset und schreibt diese Metadaten in die EFI-Variable `HibernateLocation`. Beim nächsten Start liest der Resume-Generator diese Variable und versucht die Wiederaufnahme, nachdem das LUKS-Volume entsperrt und das Gerät verfügbar ist, vor dem Mounten des Root-Dateisystems.

Deshalb werden weder `boot.resumeDevice` noch ein fester `resume_offset` eingetragen. Die aktuell in sysfs sichtbaren Resume-Werte können vor dem ersten Hibernate noch `0:0` und `0` sein. Ohne Hibernate-Abbild ist das normal.

## 1. Aktivieren und normal neu starten

```bash
cd ~/code/tobmoeller/dotfiles
dotfiles-rebuild
```

Die erste Aktivierung schreibt eine 80-GiB-Datei und kann etwas dauern. Noch kein Hibernate auslösen. Falls die Swap-Erstellung scheitert, zunächst die Fehlermeldung prüfen.

```bash
swapon --show
ls -lh /swapfile
```

Erwartet: `/swapfile` mit 80 GiB als aktiver Swap; nur root darf die Datei lesen und schreiben. Anschließend Arbeit speichern und einmal normal neu starten, damit wir für den ersten Hibernate-Test eindeutig dieselbe neue Boot- und Systemkonfiguration verwenden.

## 2. Voraussetzungen nach Neustart prüfen

```bash
swapon --show
busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate
nvidia-smi
```

`CanHibernate` sollte `yes` melden (oder `challenge`, falls eine Berechtigung benötigt wird). `no` oder `na` sind vor dem ersten Versuch zu untersuchen. Die EFI-Variable für das Hibernate-Ziel muss vor dem ersten Hibernate noch nicht existieren; sie wird erst beim Vorgang geschrieben.

## 3. Manuell testen

Arbeit speichern. Ein sichtbares Terminal oder eine Anwendung geöffnet lassen, an der sich die erhaltene Sitzung erkennen lässt. Für den Test im Plasma-Energiemenü nach Möglichkeit „Ruhezustand“ wählen, damit die Desktop-Sperre beteiligt ist. Alternativ im Terminal:

```bash
loginctl lock-session
systemctl hibernate
```

Der Rechner sollte nach dem Schreiben des Abbilds ausschalten. Anschließend mit dem Einschaltknopf starten und das LUKS-Volume wie gewöhnlich entsperren. Für diesen Test dieselbe aktuelle NixOS-Generation booten. Erwartet ist die wiederhergestellte Sitzung statt eines frischen Logins.

Danach prüfen:

```bash
nvidia-smi
nvidia-offload glxinfo -B
swapon --show
journalctl -b -u systemd-hibernate --no-pager
```

Zusätzlich Audio und Netzwerk ausprobieren. Ein erfolgreicher Build ersetzt diesen Test nicht. Bei einem frischen Login statt der alten Sitzung nicht sofort erneut hibernieren; zuerst Journal und Resume-Pfad prüfen.

## 4. Suspend-then-Hibernate

Konfiguriert sind `HibernateDelaySec=1h` und `HibernateOnACPower=no`: zunächst RAM-Schlaf, nach einer Stunde im Akkubetrieb Hibernate. Am Netzteil bleibt es beim RAM-Schlaf; beim Abziehen beginnt die Wartezeit. Ein normaler `systemctl suspend` bleibt reiner RAM-Schlaf.

Das Home-Manager-Feature `plasma-sleep` verknüpft die native `powerdevilrc` direkt ins Checkout. `LidAction=1` und `SleepMode=3` wählen Suspend-then-Hibernate beim Zuklappen und für die automatische Schlafaktion. Idle-Zeiten und die Sonderbehandlung externer Monitore behalten ihre Plasma-Vorgaben. Die ausdrücklich als RAM-Suspend angeforderte Aktion im Desktop-Menü kann weiterhin normalen Suspend auslösen. Ohne Desktop-Energieverwaltung übernimmt logind die konfigurierte Deckelaktion.

Nach dem Rebuild einmal ab- und anmelden, damit Plasma die neue Konfiguration sicher lädt. Alternativ nur die Energieverwaltung neu starten:

```bash
systemctl --user restart plasma-powerdevil.service
```

Der kombinierte Übergang wurde am 2026-10-19 im Alltag erfolgreich getestet (siehe unten). Für spätere kurze Wiederholungstests lässt sich die Verzögerung vorübergehend auf zwei Minuten verkürzen (nur bis zum Entfernen der Datei oder zum nächsten normalen Neustart):

```bash
sudo mkdir -p /run/systemd/sleep.conf.d
printf '[Sleep]\nHibernateDelaySec=2min\n' | sudo tee /run/systemd/sleep.conf.d/90-dotfiles-test.conf
```

Arbeit speichern und das Netzteil abziehen. Dann sperren und den kombinierten Vorgang starten:

```bash
loginctl lock-session
systemctl suspend-then-hibernate
```

Mindestens drei Minuten warten. Der Rechner sollte zunächst schlafen und dann nach dem Schreiben des Hibernate-Abbilds ausschalten. Anschließend einschalten, LUKS entsperren und die erhaltene Sitzung prüfen. Das erfolgreiche Wiederaufnehmen eines Hibernate-Abbilds setzt keinen normalen Neustart voraus; die Testdatei liegt dann weiterhin in `/run`.

```bash
journalctl -b -u systemd-suspend-then-hibernate.service --no-pager
nvidia-smi
nvidia-offload glxinfo -B
sudo rm /run/systemd/sleep.conf.d/90-dotfiles-test.conf
```

Audio und Netzwerk prüfen. Die letzte Zeile stellt die konfigurierte Stunde wieder her. Der kurze Test prüft den kombinierten Schlafpfad; die Deckelaktion muss anschließend separat ausprobiert werden.

## Bestätigter Test am 2026-10-18

- Swap nach Aktivierung und normalem Neustart aktiv: 80 GiB, Datei root:root, Modus 0600.
- `CanHibernate` meldet `yes`.
- Hibernate um 23:09:42 ausgelöst, erfolgreiche Wiederaufnahme um 23:12:45 protokolliert.
- Desktop-Sitzung einschließlich Codex blieb erhalten; Audio und Netzwerk funktionieren laut Benutzertest.
- NVIDIA-SMI und NVIDIA-Offload funktionieren nach der Wiederaufnahme.
- Das Kernel-Journal enthält den abgeschlossenen Hibernate-Zyklus und die anschließende Entfernung der EFI-Variable `HibernateLocation`.

Damit ist die manuelle Wiederaufnahme auf diesem Gerät einmal erfolgreich getestet. Der automatische Übergang wurde anschließend separat geprüft.

## Automatischer Übergang am 2026-10-19 bestätigt

- 13:20:45 Deckel geschlossen, 13:20:49 Beginn von Suspend-then-Hibernate.
- 14:20:52 automatischer Übergang von Suspend zu Hibernate, nach rund einer Stunde.
- 20:39:44 Deckel geöffnet, 20:39:45 erfolgreiche Wiederaufnahme und Abschluss des Dienstes.
- Der Kernel protokolliert `hibernation exit` und das Entfernen von `HibernateLocation`; die Boot-ID entspricht weiterhin der Sitzung von 12:36 Uhr.
- NVIDIA-SMI und NVIDIA-GLX-Offload nach der Wiederaufnahme erfolgreich; keine neuen NVIDIA-Xid-Fehler im Zyklus.

Damit sind Deckelaktion, verzögerter Übergang und Wiederaufnahme für einen
längeren Zyklus unter Niri bestätigt. Energieverbrauch und Lüfterverhalten
bleiben davon getrennte offene Messungen; Audio und die eigentliche
Bildschirmsperre wurden in diesem Prüfschritt nicht erneut interaktiv getestet.

## Grenzen

Der Vorfall vom 2026-10-20 nach dem Dynabook-Dock-Ausfall ist noch offen:
Suspend um 18:51, Hibernate-Übergang um 19:52 und Resume um 22:04 wurden
protokolliert, gleichzeitig meldete der Thunderbolt-Controller ICM-Fehler.
Der Benutzer beobachtete hohen Verbrauch und fehlendes Aufwachen und musste
hart ausschalten. Das erfolgreiche Wiederherstellen der Sitzung beweist keinen
zuverlässigen oder stromsparenden Gesamtzyklus. Analyse und nächste Tests stehen
in [Dock-Diagnose](dock-diagnostics.md). Die früheren Tests ohne diese Störung
bleiben einzelne erfolgreiche Versuche und keine allgemeine Zuverlässigkeitsgarantie.

Die 80 GiB geben Reserve gegenüber 64 GiB RAM. Bereits anderweitig belegter Swap reduziert den verfügbaren Platz für das Hibernate-Abbild. Das Root-Volume muss sich im Initrd entsperren lassen und EFI-Variablen müssen schreibbar bleiben.

## Quellen

- [systemd: Resume über EFI HibernateLocation](https://www.freedesktop.org/software/systemd/man/latest/systemd-hibernate-resume-generator.html)
- [systemd 260: Auswahl von Swapdatei und Offset](https://github.com/systemd/systemd/blob/v260/src/shared/hibernate-util.c)
- [systemd 260: Schreiben der EFI-Metadaten](https://github.com/systemd/systemd/blob/v260/src/sleep/sleep.c)
- [systemd: HibernateDelaySec und HibernateOnACPower](https://www.freedesktop.org/software/systemd/man/latest/systemd-sleep.conf.html)
- [Plasma 6.6: native Energieprofile](https://github.com/KDE/powerdevil/blob/Plasma/6.6/PowerDevilProfileSettings.kcfg)
- [Plasma 6.6: Werte für LidAction und SleepMode](https://github.com/KDE/powerdevil/blob/Plasma/6.6/daemon/powerdevilenums.h)
