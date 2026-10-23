# AirPods mit LibrePods

Auf dem ThinkPad ergänzt LibrePods die Bluetooth-Audioausgabe um Akkustände,
Geräuschkontrolle und Trageerkennung. Es startet mit der grafischen Sitzung
im Hintergrund; Einstellungen bleiben lokal in der Anwendung.

## Einrichtung

1. `dotfiles-rebuild` ausführen und für die neue Gruppe `librepods` neu anmelden.
2. AirPods über das Bluetooth-Menü von Noctalia oder Plasma koppeln.
3. LibrePods über das Tray-Symbol bedienen. Den eigenen Autostart-Schalter
   der Anwendung ausgeschaltet lassen; dafür sorgt bereits der Benutzerdienst.

Für hochwertige Wiedergabe A2DP verwenden; für Sprachchat bei Bedarf das
ThinkPad-Mikrofon auswählen. Musik, Geräuschkontrolle und Trageerkennung sind
nach der Aktivierung noch am Gerät zu prüfen.

## Diagnose

```bash
systemctl --user status librepods
journalctl --user -u librepods -b
systemctl --user restart librepods
```

Der Dienst verwendet den NixOS-Berechtigungswrapper; LibrePods ohne `sudo`
starten. WirePlumber ist für die Mediensteuerung eingerichtet, ein zusätzlicher
`mpris-proxy` ist nicht nötig.

[Bedienung der installierten Version](https://github.com/librepods-org/librepods/blob/v0.2.5/linux/README.md).
