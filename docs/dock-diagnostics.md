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

Dynabook veröffentlicht für die Familie **PS0120** einen Firmware-Hinweis zu
externen Video-Ausfällen. Das ist ein Prüfpunkt, keine bereits bestätigte
Zuordnung zur hier verwendeten Dock-SKU und keine Update-Empfehlung ohne
Versionsabgleich. Es wurde keine Firmware installiert.

Quellen: [Kernel: Thunderbolt/USB4](https://docs.kernel.org/admin-guide/thunderbolt.html),
[Kernel: Lane-Attribute](https://github.com/torvalds/linux/blob/master/Documentation/ABI/testing/sysfs-bus-thunderbolt),
[Kernel: USB-Fehler](https://docs.kernel.org/driver-api/usb/error-codes.html),
[Kernel: Hibernate/Resume](https://docs.kernel.org/power/swsusp.html),
[Dynabook: PS0120-Video-Firmwarehinweis](https://aps2.support.emea.dynabook.com/kb0/STC2C041O0000R01.htm).
