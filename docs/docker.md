# Docker

Der ThinkPad wählt ausdrücklich `modules.nixos.docker`: Docker Engine als
Systemdienst, Compose und Buildx aus dem fixierten Nixpkgs sowie `lazydocker`
als optionale Terminalübersicht. Die Docker-Gruppenzugehörigkeit von `tobias`
steht im Hostmodul. Diese Gruppe ermöglicht praktisch Root-Zugriff.

## Aktivieren und prüfen

```bash
dotfiles-rebuild
```

Für neue Gruppenrechte einmal neu anmelden. Bestehende herdr-Server und andere
Prozesse behalten ihre bisherigen Gruppen. Alternativ mit `newgrp docker`
eine temporäre Shell für den Test starten, anschließend mit `exit` verlassen.
Ein Systemneustart ist für Docker nicht erforderlich.

```bash
docker version
docker compose version
docker buildx version
docker run --rm hello-world
lazydocker
```

Socket-Aktivierung startet Docker bei der ersten Nutzung. Danach bleibt der
Daemon aktiv; es gibt keine automatische Leerlauf-Abschaltung. Beim Boot
werden Container mit Restart-Policy erst nach dem Start des Daemons gestartet.
Bei späteren dauerhaften Diensten `enableOnBoot` bewusst umstellen.

## Defaults

- Lokaler Unix-Socket, keine TCP-Verwaltungsschnittstelle.
- `local`-Logging mit Rotation: drei Dateien à 10 MB pro Container, komprimiert.
  `docker logs` und Compose-Logs bleiben nutzbar.
- Keine automatische Löschung von Images, Build-Caches oder Volumes.
- Keine pauschalen CPU-/RAM-Limits oder eigenen DNS-Server.
- Veröffentlichte Ports ohne explizite IP binden zunächst an `127.0.0.1`,
  sowohl beim Default-Bridge als auch bei neu angelegten Compose-Netzwerken.
  Bestehende Netzwerke übernehmen neue Defaults nicht rückwirkend.

In Projektdateien die gewünschte Adresse möglichst ausdrücklich angeben:

```yaml
ports:
  - "127.0.0.1:8080:80" # lokale Entwicklung
  # - "0.0.0.0:8080:80" # bewusst im LAN erreichbare Demo
```

Die Bind-Vorgabe ist keine allgemeine Netzwerk-Isolationsgarantie. Docker
verwaltet eigene Regeln für veröffentlichte Ports; fehlende Freigaben in
`networking.firewall.allowedTCPPorts` sind dafür kein verlässlicher Schutz.
Projekte können Daemon-Defaults ausdrücklich überschreiben.

## Erster Compose-Laufzeittest

Nach Aktivierung in einem temporären Ordner eine `compose.yaml` anlegen:

```yaml
services:
  web:
    image: nginx:stable-alpine
    ports:
      - "127.0.0.1:18080:80"
```

```bash
docker compose config --quiet
docker compose up -d --wait
curl --fail http://127.0.0.1:18080
docker compose logs --tail=20
docker compose down
```

Dies prüft Registry-Zugriff, Start, Compose-Netzwerk und Portweiterleitung.
Eigene Builds, Bind-Mount-Dateirechte und Datenbank-Volumes anschließend in
einem echten Projekt prüfen. Der bewegliche Image-Tag dient nur dem manuellen
Smoke-Test und deklariert keinen dauerhaft betriebenen Projektdienst.

## Daten und Wechsel zu Podman

`docker system df` und `docker buildx du` zeigen den Platzbedarf.
Images, Caches und Volumes sind veränderliche Laufzeitdaten, normalerweise
unter `/var/lib/docker`; je nach Storage-Konfiguration können weitere
Containerd-Daten hinzukommen. Nix-GC bereinigt diese Daten nicht.

Docker aus der Konfiguration zu entfernen beendet den Dienst und entfernt die
Pakete aus der aktuellen Umgebung. Alte Generationen können Store-Pakete
weiterhin referenzieren. Die Containerdaten bleiben ausdrücklich erhalten.
Vor einem Wechsel benötigte Daten sichern, Datenbanken bevorzugt als Dump.
Podman verwendet einen eigenen Store: Images neu laden/bauen und Volumes
bewusst übertragen. Compose-Kompatibilität am konkreten Projekt prüfen.

## Oberfläche

`lazydocker` zeigt Container, Logs und Ressourcen im Terminal, ohne zusätzlichen
Dienst. Docker Desktop betreibt unter Linux eine eigene VM mit separatem
Container-Store; es ist nicht bloß eine Oberfläche für den System-Daemon.
Portainer wäre später als Weboberfläche möglich, benötigt aber einen weiteren
Dienst. Vorerst verwenden wir CLI und Terminalübersicht.

Quellen: [Gruppenrechte](https://docs.docker.com/engine/install/linux-postinstall/),
[Logging](https://docs.docker.com/engine/logging/drivers/local/),
[Port-Bindings](https://docs.docker.com/engine/network/port-publishing/),
[Docker Desktop](https://docs.docker.com/desktop/setup/install/linux/),
[lazydocker](https://github.com/jesseduffield/lazydocker).

Prüfstand vom 2026-10-23: NixOS-Toplevel evaluiert, Flake-Checks und vollständiger
Systembuild erfolgreich. `dockerd --validate` akzeptiert die erzeugte
Konfiguration. CLI-Aufrufe bestätigen Docker 29.8.1, Compose 5.4.0, Buildx
0.31.1 und lazydocker 0.25.2. Nicht aktiviert; Container-Laufzeittests folgen
nach Aktivierung durch den Benutzer.
