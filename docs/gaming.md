# Steam auf dem ThinkPad

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
