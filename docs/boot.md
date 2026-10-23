# Grafische LUKS-Eingabe

Der ThinkPad verwendet Plymouth mit dem Standardtheme `bgrt` für Bootanzeige
und LUKS-Passworteingabe. Das System verwendet weiterhin systemd im Initrd;
Verschlüsselungsgerät, Passwort und Hibernate-Konfiguration bleiben unverändert.
Die Intel-Grafik wird im Initrd geladen, damit das interne Display verfügbar ist.
Das bestehende deutsche Konsolenlayout steht früh zur Verfügung.

```bash
dotfiles-rebuild
reboot
```

Beim nächsten Start Anzeige und Passworteingabe auf dem Notebook-Display
prüfen.
Mit `Esc` lässt sich zwischen Splash und Textanzeige wechseln.

Falls die Anzeige Probleme macht, im systemd-boot-Menü die vorherige
Generation wählen. Das Menü lässt sich beim Start durch Halten der Leertaste
anzeigen.

Evaluation, Flake-Checks und Systembuild einschließlich neuem Initrd sind
erfolgreich. Der Boot-/LUKS-Test auf dem Gerät steht nach Aktivierung noch aus.
