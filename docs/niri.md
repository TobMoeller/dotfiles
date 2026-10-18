# Erste Niri-/Noctalia-Sitzung

Niri 26.04 kommt aus dem System-Paketsatz, Noctalia 5.3.0 aus dem bereits
fixierten `nixpkgs-tools`-Input. Es gibt keinen zusätzlichen Flake-Input.
Der ThinkPad-Host wählt die NixOS- und Home-Manager-Features ausdrücklich.

Niri erscheint zusätzlich in SDDM. Plasma bleibt auswählbar. Noctalia startet
über die native Niri-Konfiguration und läuft nicht zusätzlich unter Plasma.
Konsole bleibt vorerst das Terminal; die Terminal-Auswahl ist ein eigener
späterer Schritt. Xwayland-Satellite unterstützt X11-Anwendungen, fuzzel dient
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
| Mod+Return oder Mod+T | Konsole |
| Mod+Space | Noctalia-App-Launcher |
| Mod+D | Unabhängiger fuzzel-Launcher |
| Mod+S | Control Center |
| Mod+Komma | Noctalia-Einstellungen |
| Mod+H/J/K/L oder Pfeiltasten | Fenster fokussieren |
| Mod+Ctrl+H/J/K/L | Fenster/Spalten bewegen |
| Mod+I/U | Workspace darüber/darunter |
| Mod+1 bis Mod+5 | Workspace auswählen |
| Mod+Q | Fenster schließen |
| Mod+F / Mod+M | Vollbild / Spalte maximieren |
| Mod+Shift+Space | Floating umschalten |
| Mod+Alt+L | Sperren |
| Mod+Shift+E | Sitzungsmenü |
| Mod+Ctrl+Shift+E | Niri beenden (Bestätigung) |
| Mod+Shift+Slash | Tastenkürzel anzeigen |

Lautstärke- und Helligkeitstasten sind mit Noctalia verbunden. Nach zehn Minuten
Inaktivität wird gesperrt, nach elf Minuten der Bildschirm abgeschaltet.
Ein zusätzlicher automatischer Idle-Suspend ist zunächst nicht konfiguriert.

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
