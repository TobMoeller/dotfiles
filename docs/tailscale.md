# Tailscale

Das NixOS-Feature `tailscale` installiert den Client und `tailscaled`. Der
ThinkPad ist reiner Client: kein Exit Node, kein Subnet-Router, kein
Tailscale SSH. Normaler Internet- und Spieleverkehr läuft weiter über den
lokalen Anschluss; nur Ziele aus freigegebenen Tailnet-Routen gehen durch den
Tunnel. Ziel ist das Heimnetz `192.168.178.0/24`, das ein Raspberry Pi als
Subnet-Router veröffentlicht.

Die Firewall bleibt zu. Tailscale baut Verbindungen nach außen auf und
kommt durch NAT/CGNAT notfalls über DERP-Relays.
`useRoutingFeatures = "client"` lockert nur die Rückwegprüfung
(`checkReversePath = "loose"`), damit Antworten aus dem Heimnetz nicht
verworfen werden.

## Anmelden

Einmalig nach `dotfiles-rebuild`, mit demselben privaten Tailnet wie der Pi.
Keine Auth-Keys im Repository.

```bash
sudo tailscale up --accept-routes --accept-dns=false
```

Der Befehl zeigt einen Login-Link für den Browser. `--accept-dns=false`, weil
hier kein systemd-resolved läuft: Mit MagicDNS würde tailscaled
`/etc/resolv.conf` direkt überschreiben und mit NetworkManager konkurrieren.
Heimgeräte werden per IP angesprochen.

## Bedienung

Für den Alltag `homenet` (`scripts/homenet`, verknüpft nach `~/.local/bin`):

```bash
homenet on       # verbinden, mit Heimnetzroute und ohne Tailscale-DNS
homenet off      # trennen und prüfen, dass keine Tailscale-Routen bleiben
homenet status   # Tailnet-Geräte und ob das Heimnetz über Tailscale läuft
```

`homenet on` prüft vorher, ob das lokale Netz selbst `192.168.178.x` nutzt
(siehe unten). Dann verbindet es ohne Heimnetzroute, damit das lokale LAN
erreichbar bleibt. Beim ersten `on` erscheint der Login-Link.

Direkte Befehle:

```bash
tailscale status                       # Geräte im Tailnet
tailscale ping <gerät>                 # Erreichbarkeit, direkt oder DERP
ip route show table 52                 # übernommene Routen
sudo tailscale set --accept-routes=false   # Heimnetzroute abschalten
sudo tailscale down / up               # Tunnel trennen / verbinden
```

Der Zustand bleibt über Neustarts erhalten: Nach `up` verbindet sich
Tailscale beim Booten wieder, nach `down` bleibt es getrennt. Nach `down`
läuft das Routing wieder normal; prüfen mit:

```bash
ip route show table 52    # leer
ip route get 192.168.178.1   # Ausgabe ohne "dev tailscale0"
```

Die Regeln 5210–5270 in `ip rule` bleiben stehen, solange `tailscaled`
läuft. Sie verweisen auf die leere Tabelle 52 und sind damit wirkungslos.

## Überlappende Netze

Fritzboxen verwenden standardmäßig `192.168.178.0/24`. Nutzt ein fremdes
Netz (LAN-Party, Hotel) denselben Bereich, gewinnt die Tailscale-Route:
Lokale Geräte und eventuell das Gateway sind dann nicht mehr erreichbar.
`homenet on` erkennt das und lässt die Route weg; von Hand prüfen mit
`ip -4 addr`, abschalten mit `sudo tailscale set --accept-routes=false`. Eine dauerhafte Lösung
(z. B. 4via6 oder ein anderes Heimnetz) ist noch nicht eingerichtet.
