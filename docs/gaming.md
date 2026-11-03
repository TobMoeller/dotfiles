# Steam auf dem ThinkPad

## Discord und TeamSpeak

Das separate Home-Manager-Feature `voice-chat` stellt auf dem ThinkPad den
offiziellen Discord-Client (`pkgs.discord`) und TeamSpeak 6
(`pkgs.teamspeak6-client`, im fixierten Paketstand Beta) bereit.
Nach `dotfiles-rebuild` lassen sie sich im Noctalia-Launcher über Discord
beziehungsweise TeamSpeak öffnen; im Terminal heißen sie `discord` und
`TeamSpeak`. Konten, Server und Audioeinstellungen werden direkt in den Apps
verwaltet. Mikrofon und Ausgabegerät vor dem ersten Gespräch in der jeweiligen
App testen. Push-to-talk bei nicht fokussiertem Fenster unter Niri separat
prüfen. Der entfernte alte TeamSpeak-3-Client wird nicht eingebunden.

## Gaming-Umfang

Das Gaming-Feature richtet Steam samt 32-Bit-Grafikunterstützung und
Controller-Regeln ein. GE-Proton wird über Nix bereitgestellt; reguläres
Proton und Proton Experimental verwaltet Steam. GameMode, MangoHud,
Gamescope und Protontricks sind ebenfalls installiert.

## Aktivieren und erster Start

```bash
dotfiles-rebuild
```

Für die neue Gruppenzugehörigkeit `gamemode` einmal ab- und anmelden.
Steam über den Launcher starten, seine Aktualisierung abwarten und anmelden.
Die Anmeldung und Spielinstallationen bleiben in Steam, außerhalb der Dotfiles.
Kompatibilität/Proton in den Steam-Einstellungen prüfen. Ein Windows-Spiel
kann unter Eigenschaften → Kompatibilität gezielt Proton Experimental oder
GE-Proton verwenden. Ein installiertes GE-Proton wird dadurch nicht automatisch
für alle Spiele ausgewählt.

## NVIDIA, GameMode und Overlay

Für das erste Spiel unter Eigenschaften → Allgemein → Startoptionen:

```text
nvidia-offload gamemoderun mangohud %command%
```

So läuft das Spiel auf der RTX, GameMode ist für die Spieldauer aktiv und
MangoHud zeigt FPS, Frametimes, CPU-/GPU-Auslastung, Temperaturen und Speicher.
Der Steam-Client selbst muss dafür nicht auf NVIDIA laufen.
Die native Overlay-Datei `modules/features/gaming/MangoHud.conf` ist direkt
ins Checkout verknüpft und lässt sich unabhängig von Nix anpassen.

Für einen aussagekräftigen ersten Test das Netzteil verwenden und zunächst
1920×1200 wählen; das interne Panel hat 3840×2400 Pixel. Danach Auflösung und
Details schrittweise erhöhen. Während das Spiel läuft, in einem Terminal:

```bash
nvidia-smi
```

Der Spielprozess sollte die RTX verwenden. Nicht jedes Spiel unterstützt
jede Overlay-/Optimierungskombination; bei Startproblemen erst nur
`nvidia-offload %command%` verwenden und Werkzeuge einzeln hinzufügen.
Ein installierter Client ist noch kein bestätigter Spiel-/Proton-Test.

### CPU-Turbo während des Spiels

CPU und GPU teilen sich im ThinkPad einen Kühler. Im Test am 2026-11-01
drosselte die GPU wegen Temperatur (`sw_thermal_slowdown`); ohne CPU-Turbo
stieg ihr Verbrauch von etwa 74 auf 77–80 W. Deshalb schaltet GameMode auf
diesem Host den Turbo beim Spielstart ab und am Ende wieder ein. Das gilt nur
für Spiele mit `gamemoderun`. Dafür ist
`/sys/devices/system/cpu/intel_pstate/no_turbo` für die Gruppe `gamemode`
beschreibbar.

Prüfen während des Spiels: `cat /sys/devices/system/cpu/intel_pstate/no_turbo`
liefert `1`, nach Spielende wieder `0`. Die Lüfter nicht abdecken; ein Ständer
direkt unter den Lüftern kostete im Test deutlich GPU-Leistung.

### Kühlung und Leistung: Messwerte und Quellen

Messungen am 2026-11-01 mit Spiel am Netzteil (170 W), RTX 3080 Laptop:

| Zustand | GPU-Leistung | GPU-Takt | GPU | CPU |
| --- | --- | --- | --- | --- |
| Lüfter durch Ständer verdeckt | 46–62 W | 780 MHz | 87 °C | 93 °C |
| Lüfter frei, Turbo an | ~72–74 W | – | – | – |
| Lüfter frei, Turbo aus | 75–78 W | ~1000–1035 MHz | 87 °C | 84 °C |

- Drosselgrund laut Treiber durchgehend `sw_thermal_slowdown`, nicht das
  Leistungslimit. Limits: 80 W Standard, 100 W maximal, 55 W auf Akku.
  Lüfter in Automatik bei etwa 4270 U/min.
- NVIDIA-Nenn-Boost der 80-W-Stufe: 1245 MHz
  ([Notebookcheck](https://notebookcheck.net/Comprehensive-list-of-all-laptops-featuring-the-NVIDIA-GeForce-RTX-3080-Laptop-GPU-along-with-corresponding-TGPs.517977.0.html)).
- CPU-Limits (i9-11950H): MSR 109 W dauerhaft, aber die Firmware setzt per
  MMIO 30 W dauerhaft (Fenster ~56 s) und 135 W kurzzeitig; es gilt das
  niedrigere Limit, also 30 W. Notebookcheck sah unter Windows ebenfalls
  etwa 30 W CPU bei kombinierter Last. Turbo aus senkt die CPU-Wärme
  vermutlich weiter unter dieses Limit; der echte CPU-Verbrauch ist noch
  nicht gemessen (`turbostat` braucht root).
- Notebookcheck, baugleicher X1 Extreme G4 mit RTX 3080: GPU stabil bei
  80 W, Witcher 3 Ultra ~85 FPS auf Netz und ~50 FPS auf Akku; GPU-Takt und
  -Temperatur nicht gemessen
  ([Test](https://www.notebookcheck.net/Lenovo-ThinkPad-X1-Extreme-G4-Review-The-best-Multimedia-Laptop-thanks-to-Core-i9-and-RTX-3080.588585.0.html)).
  Stärkere P1-G4-GPUs haben laut Notebookcheck eine Vapor Chamber
  ([Hinweis](https://www.notebookcheck.net/Customers-are-left-in-the-dark-Only-vapor-chamber-models-of-the-Lenovo-ThinkPad-P1-G4-X1-Extreme-G4-offer-full-CPU-performance.573365.0.html)).
- Reddit, P1 Gen 4 mit i9/RTX 3080
  ([Beitrag](https://www.reddit.com/r/thinkpad/comments/rmnaqj/p1_gen_4_repaste_round_1_great_job_on_the_thermal/)):
  schlecht sitzendes VRAM-Pad, mittelmäßige Paste, überlappende Folie. Nur
  neue Paste: CPU deutlich kühler, Spiel weiter unruhig. Zusätzlich neue
  Pads (2 mm und 0,5 mm; Thermalright Odyssey, Gelid GC Extreme): stabile
  60 FPS, nach 40 min GPU 86 °C/CPU 84 °C. Ein anderer Nutzer sah nach
  mehrfachem Neupasten keine Verbesserung. Keine GPU-Takt-Angaben.
- Einschätzung: Ein Pastenwechsel ist nur zusammen mit neuen Pads sinnvoll
  und vom Montagezustand abhängig. Mehr als 80 W lässt die Firmware nicht
  zu; erwartbar sind eher stabilere Takte und weniger Lärm als ein großer
  FPS-Sprung. Vorher/nachher mit gleicher Szene messen.
- Weitere Stellschrauben, noch nicht umgesetzt: CPU-Dauerlimit beim
  Spielen auf 20–25 W senken, `scaling_max_freq` begrenzen, FPS-Limit per
  MangoHud, Lüfter manuell über `thinkpad_acpi fan_control=1`,
  `hardware.nvidia.dynamicBoost.enable`.

## Gamescope und Reparaturwerkzeuge

Gamescope ist optional, beispielsweise als Startoption für ein Spiel:

```text
nvidia-offload gamemoderun gamescope -w 1920 -h 1200 -f -- %command%
```

Zuerst ohne Gamescope testen, danach separat. Es wird keine zusätzliche
Gamescope-Login-Sitzung eingerichtet. HDR, VRR und externe Monitore sind
eigene spätere Tests. Protontricks dient bei Bedarf zur gezielten Anpassung
eines Spiels; zunächst die normalen Proton-Vorgaben verwenden.

Es werden keine Remote-Play- oder Server-Ports geöffnet. Spiele mit Anti-Cheat
oder speziellen Launchern müssen individuell auf Proton-Unterstützung geprüft
werden. Ein konkreter erster Titel wird zusammen mit dem Benutzer gewählt.

## Fensterleisten und Diagnose

Niris globale Option `prefer-no-csd` fordert unterstützte Wayland-Anwendungen
zum Weglassen ihrer eigenen Dekorationen auf. Sie ist keine Steam-spezifische
Einstellung für die Menü-/Titelleiste. Steam zeichnet seine eigene Oberfläche;
eine gezielte Anpassung ist noch offen. Super+Q schließt das fokussierte Fenster.

Am 2026-10-19 um 01:07:25 wurde bei einer Diagnose des Agenten mit
`steam --version` ein 32-Bit-`ldconfig` durch die Ausführungs-Sandbox beendet
(`SIGSYS`/Seccomp). Das ist von einem Absturz beim normalen Steam-Start zu
unterscheiden. Steam-Diagnosebefehle, die die FHS-Umgebung starten, künftig
nicht in dieser eingeschränkten Sandbox ausführen.

Quellen: [NixOS Steam](https://wiki.nixos.org/wiki/Steam),
[GameMode](https://github.com/FeralInteractive/gamemode),
[MangoHud](https://github.com/flightlessmango/MangoHud).
