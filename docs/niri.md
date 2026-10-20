# Erste Niri-/Noctalia-Sitzung

Niri 26.04 kommt aus dem System-Paketsatz, Noctalia 5.3.0 aus dem bereits
fixierten `nixpkgs-tools`-Input. Es gibt keinen zusätzlichen Flake-Input.
Der ThinkPad-Host wählt die NixOS- und Home-Manager-Features ausdrücklich.

Niri erscheint zusätzlich in SDDM. Plasma bleibt auswählbar. Noctalia startet
über die native Niri-Konfiguration und läuft nicht zusätzlich unter Plasma.
Ghostty ist das Terminal. Xwayland-Satellite unterstützt X11-Anwendungen, fuzzel dient
als unabhängiger Launcher. Die NixOS-Niri-Integration richtet Portale und
GNOME-Keyring ein; der Dateidialog verwendet GTK.

## Aktivieren und anmelden

```bash
dotfiles-rebuild
```

Arbeit speichern, aus Plasma abmelden und in SDDM die Sitzung **Niri** wählen.
Ein Neustart ist dafür nicht erforderlich. Abmelden beendet die bisherigen
Anwendungen; eine Codex-Sitzung im Terminal gegebenenfalls später fortsetzen.

## Erste Tastenkürzel

`Mod` ist die Super-/Windows-Taste.

| Tasten | Aktion |
| --- | --- |
| Mod+Return oder Mod+T | Ghostty |
| Mod+Space | Noctalia-App-Launcher |
| Mod+D | Unabhängiger fuzzel-Launcher |
| Mod+S | Control Center |
| Mod+Komma | Noctalia-Einstellungen |
| Mod+H/J/K/L oder Pfeiltasten | Fenster fokussieren |
| Mod+Alt+Links/Rechts | Linken/rechten Monitor fokussieren |
| Mod+Shift+Links/Rechts | Aktives Fenster auf linken/rechten Monitor verschieben |
| Mod+Ctrl+H/J/K/L | Fenster/Spalten bewegen |
| Mod+I/U | Workspace darüber/darunter |
| Mod+1 bis Mod+5 | Workspace auswählen |
| Mod+Q | Fenster schließen |
| Mod+F | Fenster maximieren, Leiste bleibt sichtbar |
| Mod+Shift+F | Echtes Vollbild |
| Mod+M | Spalte auf volle Breite bringen |
| Mod+Shift+Space | Floating umschalten |
| Mod+Alt+L | Sperren |
| Mod+Shift+E | Sitzungsmenü |
| Mod+Ctrl+Shift+E | Niri beenden (Bestätigung) |
| Mod+Shift+Slash | Tastenkürzel anzeigen |

Lautstärke- und Helligkeitstasten sind mit Noctalia verbunden. Nach zehn Minuten
Inaktivität wird gesperrt, nach elf Minuten der Bildschirm abgeschaltet.
Ein zusätzlicher automatischer Idle-Suspend ist zunächst nicht konfiguriert.

Größenänderungen sind ohne Animation; andere Animationen bleiben aktiv.
Das Touchpad verwendet traditionelle Scrollrichtung (`natural-scroll` aus).
Firefox-Fenster starten ausdrücklich als normale gekachelte Fenster, auch
wenn Firefox zuvor maximiert oder im Vollbild beendet wurde. Diese Startregel
wirkt auf neue Fenster; spätere manuelle Maximierung/Vollbild bleiben möglich.

Die bisherigen Gesten von Niri 26.04 sind fest vorgegeben: drei Finger
horizontal bewegen die Ansicht, vertikal wechseln sie Workspaces; vier Finger
vertikal öffnen/schließen die Übersicht. Eine freie Umbelegung auf Browser-Zurück
oder horizontales Vier-Finger-Workspace-Wechseln ist nicht nativ konfigurierbar.
Ein externer Listener allein verhindert nicht die parallele Niri-Geste.

Beim Zuklappen greift außerhalb Plasma die vorhandene logind-Aktion
Suspend-then-Hibernate. Noctalia soll davor die Sitzung sperren. Der Lockscreen
verwendet den bestehenden PAM-Dienst `login`; keine neue Authentifizierungsmethode.
Entsperren und Deckelaktion müssen in der neuen Sitzung geprüft werden.

## Native Dateien und Tests

- `modules/features/niri/config.kdl` → `~/.config/niri/config.kdl`
- `modules/features/noctalia/config.toml` → `~/.config/noctalia/config.toml`

Beide Dateien sind direkt ins Checkout verknüpft und werden neu geladen.
Noctalia speichert GUI-Änderungen separat in
`~/.local/state/noctalia/settings.toml`; diese haben Vorrang vor der Repo-Datei.
Gewünschte Änderungen später gezielt in die TOML-Datei übernehmen.

```bash
niri validate
noctalia config validate
niri msg outputs
```

Beim ersten Login Terminal, Launcher, WLAN, Audio, Helligkeit, Sperren/Entsperren
und NVIDIA-Offload ausprobieren. Skalierung, Monitoranschlüsse, Screencasting
und Spiele folgen separat. Ein erfolgreicher Build prüft keinen laufenden
Desktop. Bei Problemen über das Sitzungsmenü abmelden und Plasma auswählen.

Quellen: [Niri-Start](https://niri-wm.github.io/niri/Getting-Started.html),
[Noctalia/Niri](https://docs.noctalia.dev/noctalia/compositor-settings/niri/),
[Noctalia-Konfiguration](https://docs.noctalia.dev/noctalia/configuration/).

## ThinkPad am Dynabook-Dock

Die hostbezogene Datei `hosts/thinkpad/niri-outputs.kdl` wird über Home Manager
als `~/.config/niri/outputs.kdl` verknüpft. Die gemeinsame Niri-Konfiguration
lädt sie optional; andere Hosts benötigen keine Monitorkonfiguration. Für den
neuen Symlink einmal `dotfiles-rebuild` ausführen. Native Änderungen werden
danach direkt neu geladen. Bis dahin gelten die per IPC gesetzten Positionen
und Modi nur für die laufende Sitzung.

Anordnung, von links nach rechts:

| Display | Modus | Skalierung | Position |
| --- | --- | --- | --- |
| ThinkPad, eDP-1 | 3840×2400, 60 Hz | 225 % | 0, 0 |
| Dell S2725DC, GR9HQC4 | 2560×1440, vorläufig 60 Hz | 100 % | 1707, 0 |
| Dell S2725DC, HM1XPB4 | 2560×1440, vorläufig 60 Hz | 100 % | 4267, 0 |

Die Dells werden über Hersteller/Modell/Seriennummer erkannt, unabhängig von
wechselnden DP-Steckernamen am Dock. 1707 ist die aufgerundete logische Breite
des Notebook-Displays bei 225 %. Die externen Displays bleiben in ihrer
bisherigen relativen Reihenfolge. Alle Oberkanten sind ausgerichtet.

Prüfung am 2026-10-20: Beide Dells bieten maximal 143,973 Hz in WQHD an;
165 Hz wird nicht angeboten. Beide wurden gleichzeitig auf 143,973 Hz
umgestellt, danach meldete der Benutzer Flackern rechts. Rechts 59,951 Hz
bei weiterhin links 143,973 Hz behob es nicht. Daher beide auf den
ursprünglichen 59,951-Hz-Modus zurückgesetzt; Rückmeldung zur Stabilität steht
noch aus. VRR blieb deaktiviert. Einen höheren Modus erst nach Klärung von
Dock-Modell, Kabeln und gemeinsamer Verbindung erneut testen.

Die externen DP-Ausgänge liegen an der RTX 3080, das interne Display an
Intel. Desktop-Ausgabe mit drei Displays wurde erkannt; daraus folgt keine
garantierte Spiele-Framerate. Spiele bei Bedarf wie in `docs/gaming.md`
über NVIDIA-Offload starten.

Ethernet war mit 1000 Mbit/s verbunden und die bevorzugte Standardroute
(Metrik 100 gegenüber WLAN 600); die tatsächliche Internet-Übertragungsrate
wurde nicht gemessen. Die Focusrite Scarlett Solo (3rd Gen.) war als
Standardausgabe und Eingang 1/Mikrofon ausgewählt, TeamSpeak-Ausgabe darüber
aktiv. Aufnahmepegel bei Bedarf im Sprachchat prüfen.

Versorgung ausschließlich über das Dynabook-Dock: USB Power Delivery aktiv,
Akku bei 65–66 % am Laden. Die Ladeleistung schwankte während der Prüfung;
die maximal ausgehandelte Dock-Leistung ließ sich nicht verlässlich auslesen.
Für Spiele das passende Lenovo-Netzteil zusätzlich anschließen. Laden im
Desktopbetrieb belegt keine ausreichende Versorgung unter Spielelast.

Die Mauskonfiguration setzt bisher kein eigenes Beschleunigungsprofil;
Niris Standard ist `adaptive`. Eine explizite `mouse { accel-profile "flat"; }`
würde die geschwindigkeitsabhängige Beschleunigung abschalten. Touchpad und
TrackPoint lassen sich unabhängig davon konfigurieren.
