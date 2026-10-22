# Dynabook-Dock und Schlafzustand: Analyse vom 2026-10-20

Analyse vorhandener Logs, keine neuen Dock-/Schlafversuche und keine Änderung
an Treibern, Firmware oder Energieeinstellungen. Der Benutzer meldet Flackern,
Verbindungsausfälle, hohen Verbrauch nach dem Zuklappen und ein erforderliches
hartes Ausschalten. Dass die Sitzung erhalten blieb, wird gesondert erklärt.

## Thunderbolt war aktiv

- Kernel erkennt `Dynabook Thunderbolt 4 Dock`, Vendor `0x236`, Device `0x22`.
- Das Gerät erschien unter `/sys/bus/thunderbolt/devices/0-3` mit `authorized=1`.
- PCIe-Bridges unterhalb von `0000:00:07.0` wurden angelegt.
- USB-Hubs, Ethernet und Focusrite sind zusätzliche Funktionen der Verbindung;
  ihre Anzeige als USB-Geräte bedeutet keinen ausschließlichen USB-Betrieb.
- `rx_speed` und `tx_speed` wurden mit jeweils `20.0 Gb/s` gelesen. Diese
  Angaben gelten pro Lane. Die Lane-Anzahl wurde damals nicht erfasst; daraus
  lässt sich die gesamte Linkrate noch nicht ableiten. Beim späteren Auslesen
  um 22 Uhr war das Dock nicht mehr vorhanden.

Das Dock funktioniert laut Benutzer an einem Ubuntu-Notebook mit beiden
externen Displays oberhalb von 100 Hz. Ein grundsätzliches 60-Hz-Limit oder
ein defektes Dock ist damit nicht belegt. Ob dabei dieselben Kabel und Ports
verwendet wurden, muss beim nächsten Vergleich erfasst werden.

## Fehler vor dem Zuklappen

Um 18:41 kam es zu wiederholtem Ab- und Wiederanmelden des Thunderbolt-Geräts
und seiner USB-Geräte. Zu den konkreten Meldungen gehören:

```text
thunderbolt 0-3: failed to initialize port 3
pcieport 0000:20:00.0: not ready 1023ms after resume; giving up
usb 3-4.2-port3: cannot reset (err = -71)
thunderbolt 0-3: device disconnected
```

Auch die PCIe-Common-Clock-Konfiguration wurde beim Wiederanmelden neu gesetzt.
Diese Meldung allein beweist keinen Fehler. Die fehlgeschlagene Bereitschaft
der Bridge und die wiederholten Abbrüche sind dagegen konkrete Ansatzpunkte
für die Untersuchung von Verbindung, Runtime-PM, Kernel und Firmware.

Nach dem Ausfall fehlten Ethernet und beide externe Displays. USB-2-Geräte
einschließlich Focusrite wurden erneut erkannt. Netzversorgung wurde mit
`AC/online=0` und `Discharging` gemeldet; USB-PD war nicht mehr wie zuvor aktiv.
Welche Linkwechsel automatisch und welche durch manuelles Umstecken ausgelöst
wurden, ist nicht vollständig bekannt. Keine einzelne Ursache ist bewiesen.

Hunt verwendete die RTX 3080 (`HuntGame.exe`, anfangs etwa 1,6 GiB VRAM).
Die GPU-Auswahl war korrekt; die Ursache des Hängers ist damit nicht geklärt.

## Zuklappen und erhaltene Sitzung

Alle folgenden Einträge gehören zur gleichen Boot-ID
`6792efa2-3f2b-4ad6-a83d-dcf42b77e7ba`:

| Zeit, CEST | Protokollierter Vorgang |
| --- | --- |
| 18:51:15 | Deckel geschlossen, Suspend-then-Hibernate ausgelöst |
| 18:51:17 | `user.slice` eingefroren, `PM: suspend entry (s2idle)` |
| 19:52:40–41 | Rückkehr aus Suspend, Übergang zu Hibernate |
| 22:04:07–08 | Wiederaufnahme des Hibernate-Abbilds, `hibernation exit`, Auftauen der Sitzung |

Bei den Übergängen meldet der Thunderbolt-Controller `0000:00:0d.2`:

```text
failed to send driver ready to ICM
```

ICM ist der Firmware-Connection-Manager des Thunderbolt-Controllers. Die
Meldung zeigt eine fehlgeschlagene Treiber-/Firmware-Kommunikation; sie
beweist weder einen bestimmten Kernel-Bug noch einen Hardwaredefekt.

Der erhaltene Boot-Kontext und das protokollierte Hibernate-Resume erklären
die erhaltene Sitzung. Ein zuvor geschriebenes Hibernate-Abbild kann auch
nach zwischenzeitlichem Ausschalten wieder geladen werden. Aus diesen Logs
allein lässt sich nicht rekonstruieren, wann genau der lange Druck auf den
Power-Knopf erfolgte oder ob das Gerät selbständig vollständig ausschaltete.
Die Zeitstempel gepufferter Kernel-Meldungen beim Restore sind ebenfalls
nicht als unabhängige Messung der Abschaltdauer zu behandeln.

Der Schlafdienst meldete am Ende Erfolg. Die Suspend-Zähler zeigen sieben
erfolgreiche und keine fehlgeschlagenen Vorgänge. Das belegt keinen zuverlässig
stromsparenden Zustand: `last_hw_sleep` wurde mit 0 gelesen, eine isolierte
Verbrauchsmessung fehlt. Die Benutzerbeobachtung wird dadurch nicht entkräftet.

## Erfasster Stand

- Kernel `6.18.56`, NVIDIA `595.71.05`, Niri `26.04`.
- BIOS `N40ET50W (1.32)`, Datum `2025-06-18`; Aktualität noch nicht verifiziert.
- Firmware bietet für RAM-Schlaf nur `s2idle` an; `deep` wird nicht angeboten.
- NVIDIA: `PreserveVideoMemoryAllocations=1`, `UseKernelSuspendNotifiers=1`,
  `DynamicPowerManagement=1`, temporäre Datei unter `/var/lib/nvidia-sleep`.
- In den untersuchten Ereignisabschnitten keine NVIDIA-Xid-Meldung gefunden.
  Ein generelles NVIDIA-Problem ist damit nicht ausgeschlossen.

## Nächster kontrollierter Test, erst mit dem Benutzer

1. Einen echten Kaltstart und Zustand ohne Dock als Ausgangspunkt erfassen.
   Netzversorgung für den Test über das passende Lenovo-Netzteil bereitstellen.
2. Dock-SKU und Firmwarestand erfassen; am Ubuntu-Gerät Kernel, Grafikpfad,
   Kabel, Dock-Ports und aktive Monitor-Modi vergleichen.
3. Beim Verbinden `authorized`, `rx_speed`, `rx_lanes`, `tx_speed`, `tx_lanes`
   sowie Stromversorgung und Kernel-Logs erfassen. Autorisierung war bereits
   vorhanden; deren Fehlen ist bisher keine Erklärung des Ausfalls.
4. Erst einen externen Monitor ohne Spiel testen, danach zwei bei 60 Hz.
   Wenn stabil, höhere Bildraten schrittweise prüfen. Jede Änderung einzeln.
5. Ein einzelnes Display direkt am Notebook als Vergleich zum Dock verwenden.
6. Dock-/Host-Firmware und Kernel-Kompatibilität anhand der Befunde prüfen.
   Gezielte Runtime-PM- oder Kernel-Vergleiche erst nach reproduzierbarem
   Ausgangszustand; keine pauschalen ASPM-/USB-/NVIDIA-Workarounds gleichzeitig.
7. Schlaf separat ohne und mit Dock prüfen, einschließlich tatsächlichem
   Verbrauch, Wiederaufnahme und Verhalten am Netzteil. Ein erfolgreiches
   Hibernate-Resume allein genügt nicht als Gesamtfreigabe.

## Vergleich am 2026-10-22: Render-GPU

Das Dock wurde erneut angeschlossen, diesmal unter Thunderbolt `1-1`.
`rx_speed` und `tx_speed` waren jeweils `20.0 Gb/s`, mit jeweils zwei Lanes:
damit sind 40 Gbit/s pro Richtung ausgehandelt. Der Akku meldete bei 60 %
`Charging`, `AC/online=1`. Welcher physische Port und welches Netzteil verwendet
wurden, ist noch nicht bestätigt. Im überprüften Logabschnitt gab es zunächst
keine erneuten Thunderbolt-Abbrüche.

Beide Dells wurden bei aktivem Notebook-Display mit 2560×1440 bei 59,951 Hz
getestet, VRR war aus. Der Benutzer meldet weiterhin Flackern, besonders beim
Verschieben von Fenstern zwischen Monitoren. Niri verwendet laut Startlog
`/dev/dri/renderD128`; sysfs ordnet diesen Intel (`0x8086`) und `renderD129`
NVIDIA (`0x10de`) zu.

Für den nächsten Vergleich setzt `hosts/thinkpad/niri-outputs.kdl` vorübergehend
`debug.render-drm-device` auf `/dev/dri/renderD129`. Beide Dells bleiben bei
60 Hz aktiv, ebenso das interne Display. Der zuvor fehlende, bereits in Home
Manager deklarierte Link `~/.config/niri/outputs.kdl` wurde angelegt. Niri
validiert die komplette Konfiguration. **Die neue Render-GPU erfordert eine
neue Sitzung; zum Zeitpunkt der Vorbereitung lag noch kein Testergebnis vor.**
BIOS, PRIME-Modus und Treiber bleiben unverändert, die Intel-Ausgabe für das
interne Display bleibt verfügbar. Die Render-Node-Nummer ist für diesen Boot
geprüft und muss nach einem Neustart erneut zugeordnet werden.

Zurück zu automatischer GPU-Auswahl: den temporären `debug`-Block entfernen
und neu anmelden. Zurück zum vorherigen Monitorprofil: im rechten Dell-Block
`off` ergänzen und links wieder `2560x1440@143.973` setzen. Monitoränderungen
werden live geladen; die Render-GPU wechselt erst beim nächsten Sitzungsstart.

### Ergebnis und erneuter Start am selben Abend

- Neue Niri-Sitzung um 21:53:22: Startlog bestätigt `renderD129` (NVIDIA).
  Benutzer meldet zunächst eine Verbesserung, beim Start von TeamSpeak jedoch
  einen Absturz und danach den Ausfall des Docks. Eine stabile Freigabe des
  Monitorbetriebs ist daraus nicht ableitbar.
- Um 21:53:54 stürzt TeamSpeaks `hotkey_helper` mit SIGSEGV ab. In derselben
  Sekunde wird das Thunderbolt-Gerät getrennt. Die zeitliche Nähe beweist
  keine Kausalität. Niri läuft weiter; der alte Sitzungssocket war lediglich
  nach der Neuanmeldung ungültig.
- Danach wiederholte Abbrüche und `not ready 1023ms after resume; giving up`
  an den Dock-Bridges unter beiden Thunderbolt-Domains. Welche Portwechsel
  der Benutzer manuell ausführte, ist nicht vollständig erfasst.
- Benutzer meldet Neustart gegen 22 Uhr; ein neuer Kernel-Boot ist bestätigt.
  Ob zuvor vollständig heruntergefahren wurde, ist nicht bestätigt. NVIDIA
  bleibt korrekt zugeordnet. Zunächst nur USB-2-Geräte und internes Display;
  nach erneutem Verbinden wiederholt sich die Thunderbolt-Abbruchschleife.
- Test: `power/control=on` für Host-NHI `0000:00:0d.3` und PCIe-Root-Port
  `0000:00:07.2`. Beide werden aktiv, Abbrüche bleiben bestehen; eine externe
  Anzeige erscheint nur kurz. Benutzer setzt beide anschließend auf `auto`
  zurück; Rücksetzung aus sysfs bestätigt. Keine dauerhafte PM-Regel erstellt.
- Nach Entfernen der zuvor sichtbaren USB-Peripherie bleiben die Abbrüche
  bestehen. Der genaue Zeitpunkt des Abziehens der Monitorkabel ist nicht
  gesondert protokolliert.
- Dock-SKU nun bestätigt: **PS0120EA1PRP**, originales Dock-Kabel. Benutzer
  bestätigt, dass dasselbe Dock mit dem Tuxedo-Notebook unter Ubuntu arbeitet.
  Dies grenzt auf die ThinkPad-/Software-Kombination ein, unterscheidet aber
  noch nicht zwischen Host-Hardware, Host-Firmware und Linux-Konfiguration.
- Lokal installierte ThinkPad-Firmware: BIOS `1.32`, EC `1.18`. Die vorhandenen
  LVFS-Metadaten bieten BIOS `1.35` an. Für `1.34` und `1.35` sind
  Downgrade-Grenzen dokumentiert; in den gelesenen Hinweisen ist kein konkreter
  Fix dieser Abbruchschleife genannt. Keine Firmware installiert oder vorgemerkt.

Nächster aussagekräftiger Vergleich wäre ein Ubuntu-Live-System **auf dem
ThinkPad selbst**, ohne Installation. So bleiben Notebook, Dock und Kabel
gleich, während Kernel und Softwareumgebung wechseln. Ein Erfolg würde auf
Unterschiede im Softwarestack hindeuten; ein Misserfolg allein beweist noch
keinen Hardwaredefekt. BIOS-/Dock-Updates erst nach Versionsabgleich und
gesonderter Entscheidung; Firmware-Flash nicht über die instabile Verbindung.

### Dockversuch auf Benutzerwunsch beendet

Am 2026-10-22 wird der Versuch beendet; weitere Dock-Tests sind vorerst nicht
gewünscht. Der temporäre NVIDIA-Render-Override wurde entfernt und das bisherige
Monitorprofil wiederhergestellt: Notebook aktiv, linker Dell bei 143,973 Hz,
rechter Dell aus. Die Monitorkonfiguration wird live geladen, die automatische
Render-GPU-Auswahl gilt erst beim nächsten regulären Sitzungsstart. Dafür wird
die laufende Sitzung nicht beendet. Die beiden getesteten PM-Einstellungen
stehen bereits wieder auf `auto`. Es wurden keine Firmwareupdates installiert.
Mausbeschleunigung bleibt ausgeschaltet, die ergänzten Monitor-Shortcuts bleiben
erhalten. Die Dock-Verbindung selbst ist damit nicht repariert.

Dynabook veröffentlicht für die Familie **PS0120** einen Firmware-Hinweis zu
externen Video-Ausfällen. Das ist ein Prüfpunkt, keine bereits bestätigte
Zuordnung zur hier verwendeten Dock-SKU und keine Update-Empfehlung ohne
Versionsabgleich. Es wurde keine Firmware installiert.

Quellen: [Kernel: Thunderbolt/USB4](https://docs.kernel.org/admin-guide/thunderbolt.html),
[Kernel: Lane-Attribute](https://github.com/torvalds/linux/blob/master/Documentation/ABI/testing/sysfs-bus-thunderbolt),
[Kernel: USB-Fehler](https://docs.kernel.org/driver-api/usb/error-codes.html),
[Kernel: Hibernate/Resume](https://docs.kernel.org/power/swsusp.html),
[Dynabook: PS0120-Video-Firmwarehinweis](https://aps2.support.emea.dynabook.com/kb0/STC2C041O0000R01.htm).
