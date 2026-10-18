# Prüfung des Grundgerüsts

Am 2026-10-18 auf dem ThinkPad durchgeführt:

- `nix flake check --no-build`: erfolgreich, einschließlich NixOS-Konfiguration.
- `nix eval --raw .#nixosConfigurations.thinkpad.config.system.build.toplevel.drvPath`: erfolgreich.
- `nix build --no-link --print-out-paths .#nixosConfigurations.thinkpad.config.system.build.toplevel`: erfolgreich.
- Neue Nix-Dateien mit dem Flake-Formatter formatiert; die generierte Hardwaredatei blieb unverändert.
- `cmp /etc/nixos/hardware-configuration.nix hosts/thinkpad/hardware-configuration.nix`: identisch.
- `git diff --cached --check`: erfolgreich.
- herdr 0.9.5 ist im gebauten Benutzerprofil enthalten; CLI startet und die verwendeten Konfigurationsschlüssel sind in der Standardkonfiguration vorhanden.

Bei den Nix-Aufrufen war zusätzlich `--extra-experimental-features 'nix-command flakes'` erforderlich, da die neue Nix-Konfiguration noch nicht aktiviert ist.

Gebautes System:

```text
/nix/store/7ap5db89hgx95sy62x2vks26vm5lzij7-nixos-system-nixos-26.05.20261015.26f4107
```

Nix meldet für die zusätzliche Ausgabe `modules` eine Warnung „unknown flake output“. Diese Ausgabe stammt absichtlich aus flake-parts und stellt die wiederverwendbaren Module bereit; sie gehört nicht zu den von Nix selbst standardisierten Ausgaben. Alle Prüfungen waren erfolgreich.

Keine Aktivierung, kein Neustart und keine interaktive herdr-Sitzung durchgeführt. Boot, Grafik, Suspend und Home-Manager-Aktivierung am bestehenden Benutzerprofil müssen nach bewusster Aktivierung geprüft werden. Die direkt verknüpfte TOML-Datei ist bewusst nicht Bestandteil eines unveränderlichen Konfigurations-Snapshots.

## Host-Auswahl und Rebuild-Script

Am selben Tag wurde die Ausgabe von `nixosConfigurations.thinkpad` auf den tatsächlichen Hostnamen `nixosConfigurations.nixos` umgestellt. Ausgabe und `networking.hostName` verwenden dieselbe Bindung im Hostmodul. Die obigen ursprünglichen Prüfaufrufe dokumentieren den Stand vor dieser Umstellung.

Erneut geprüft:

- `nix flake check --no-build` und Auswertung von `nixosConfigurations.nixos.config.system.build.toplevel.drvPath`: erfolgreich.
- `scripts/rebuild build`: erfolgreich; dieselbe Systemableitung und derselbe Systempfad wie oben.
- `bash -n scripts/rebuild` und Hilfeausgabe: erfolgreich.
- Automatische Host-Auswahl und explizite Auswahl mit `--host nixos` über `--dry-run`: erfolgreich, auch aus `/tmp` heraus.
- Unbekannte Hosts, fehlende Hostnamen und mehrere Aktionen werden abgelehnt.

Auch bei diesen Prüfungen wurde keine Konfiguration aktiviert. Der erste sudo-Probelauf der Aktivierung konnte mangels interaktiver Passworteingabe nicht ausgeführt werden; dafür steht `scripts/rebuild dry-activate` im Benutzerterminal bereit.

## Vereinfachung nach der ersten Aktivierung

Die obigen Script-Prüfungen beziehen sich auf die erste, umfangreichere Version. Der Helfer wurde anschließend auf Verzeichniswechsel und `sudo nixos-rebuild switch --flake .` reduziert. Host-Auswahl und Fehlerbehandlung übernimmt direkt `nixos-rebuild`. Bash-Syntax geprüft; die Vereinfachung wurde nicht erneut aktiviert.

Beim Prüfen zeigte `/run/current-system` bereits auf den oben dokumentierten Systempfad: Die erste Aktivierung war inzwischen erfolgt. Flakes sind damit in der laufenden Konfiguration eingeschaltet. Für einen Probelauf gilt jetzt direkt `sudo nixos-rebuild dry-activate --flake .` aus dem Repository.

## NVIDIA-Vorbereitung

Am 2026-10-18:

- NVIDIA/PRIME-Feature und PCI-Bus-IDs anhand der Hardware vorbereitet.
- `nix flake check --no-build`: erfolgreich.
- NVIDIA-Paketversion ausgewertet: `595.71.05` aus dem fixierten System-Nixpkgs.
- NixOS-Toplevel ausgewertet und vollständig mit `nix build --no-link --print-out-paths .#nixosConfigurations.nixos.config.system.build.toplevel` gebaut.

```text
/nix/store/06gd0sgxk673ml651hvzqs65yh0xxw19-nixos-system-nixos-26.05.20261015.26f4107
```

Keine Aktivierung oder Änderung des Boot-Standards durchgeführt. Auf dem laufenden System ist weiterhin Nouveau geladen. Der neue Stand enthält auch die zuvor vorbereitete DOTFILES-/Bash-Einbindung. Treiberfunktion, Offload, externe Monitore und Suspend müssen nach dem Neustart geprüft werden; Anleitung in `thinkpad-hardware.md`. Swap und Hibernate sind für den anschließenden Schritt vorgesehen.

## Erster Suspend-Test und Folgeversuch

Nach Neustart bestätigte der Benutzer funktionierendes NVIDIA-SMI, Intel-Rendering, NVIDIA-Offload und Runtime-Suspend. Am 2026-10-18 schlug anschließend NVIDIA-Resume aus s2idle fehl: Kernel-Logs enthalten um 22:20:33 einen GSP-Panic (Xid 120), gefolgt von Xid 154 / GPU Reset Required. `nvidia-smi` erreicht die GPU seitdem nicht mehr.

Ein gezielter Folgeversuch ist vorbereitet: nur auf dem ThinkPad `kernelSuspendNotifier=false` und `NVreg_UseKernelSuspendNotifiers=0`. NVIDIA 595.71.05, VRAM-Erhalt und Runtime-Energieverwaltung bleiben bestehen.

- Flake-Prüfung und Toplevel-Auswertung erfolgreich.
- Ausgewertete Konfiguration enthält Parameterwert `0` sowie die NVIDIA-Suspend-/Resume-Dienste.
- Vollständiger Systembuild erfolgreich:

```text
/nix/store/204ahr7nk7djp1rj0dk9j639n5xfrvwq-nixos-system-nixos-26.05.20261015.26f4107
```

Nicht aktiviert; der Wiederholungstest nach Neustart steht aus. Noch keine Aussage, ob dieser Wechsel den Firmware-Absturz auf diesem Gerät behebt. Noch kein Swap/Hibernate eingerichtet und kein Zwischencommit erstellt.

## Erfolgreicher Suspend-Workaround und vorbereiteter Hibernate-Test

Mit `DynamicPowerManagement=1` und `UseKernelSuspendNotifiers=1` hat der Benutzer nach mehreren Suspend-Zyklen funktionierendes NVIDIA-SMI und GLX-Offload bestätigt. Für den Zyklus 22:53:19–22:56:18 wurden 174,47 Sekunden Hardware-Schlaf gemeldet, ohne neue Xid-Fehler. Die kurze Akku-Messung erfasste 0,39 Wh über 224 Sekunden einschließlich rund 45 Sekunden Wachzeit; daraus lässt sich kein genauer reiner Schlafverbrauch ableiten. Ohne Netzteil wurden keine laufenden Lüfter beobachtet.

Für Swap/Hibernate am 2026-10-18 geprüft:

- UEFI-Boot, Secure Boot deaktiviert, systemd im Initrd bereits aktiv.
- Das entsperrte Root-Volume liefert udev eine ext4-Dateisystem-UUID für die EFI-gestützte Resume-Erkennung.
- Flake-Prüfung und NixOS-Toplevel-Auswertung erfolgreich.
- Ausgewertet: `/swapfile`, 81920 MiB, keine zusätzliche Zufallsverschlüsselung, systemd-Initrd, kein statisch festgelegtes Resume-Gerät oder Offset.
- Vollständiger Build erfolgreich; Swap-Erstellungsdienst mit restriktiver Umask und generierte Sleep-Konfiguration geprüft.

```text
/nix/store/5qjac388dgg19v7d4g6ak5djxv90610h-nixos-system-nixos-26.05.20261015.26f4107
```

Dieser Stand wurde noch nicht aktiviert. Die Swapdatei existiert noch nicht; Hibernate und Wiederaufnahme wurden noch nicht getestet. Zuklappen/Idle wurden nicht auf Suspend-then-Hibernate umgestellt. Testanleitung: `docs/hibernate.md`. Der Zwischencommit folgt nach erfolgreicher Einrichtung.

## Manueller Hibernate-Test erfolgreich

Der Benutzer hat den oben gebauten Stand aktiviert und normal neu gestartet. `/swapfile` ist mit 80 GiB aktiv, root:root und Modus 0600; login1 meldet `CanHibernate=yes`.

Am 2026-10-18 wurde Hibernate um 23:09:42 ausgelöst. Die wiederhergestellte Sitzung protokolliert um 23:12:45 `System returned from sleep operation 'hibernate'` und einen erfolgreichen Abschluss des Dienstes. Das Kernel-Journal enthält den Hibernate-Zyklus und die Entfernung von `HibernateLocation` nach der Wiederaufnahme. In diesem Zeitfenster gibt es keine neuen NVIDIA-Xid-Fehler.

Der Benutzer bestätigt erhaltene Sitzung einschließlich Codex, funktionierendes Audio und Netzwerk. NVIDIA-SMI und GLX-Offload sind nach dem Wiederaufwachen erfolgreich. Aktiver Systempfad entspricht dem geprüften Build oben.

Der manuelle Test ist damit erfolgreich. Die noch nicht umgestellte automatische Desktop-Schlafaktion und der Übergang von Suspend zu Hibernate bleiben separate nächste Schritte.

## Automatische Schlafaktion vorbereitet

Für denselben Zwischencommit ergänzt: native Plasma-Konfiguration mit `LidAction=1` und `SleepMode=3` in allen drei Energieprofilen sowie logind-Deckelaktion als Fallback. Die bestehende Stunde Verzögerung im Akkubetrieb bleibt erhalten.

- Ausgewertet: NixOS-Toplevel erfolgreich; Flake-Prüfung erfolgreich (bekannte Warnung zum benutzerdefinierten Output `modules`).
- Gebaut: vollständiges System erfolgreich unter `/nix/store/g5q510sxsz7zrll7n5bd6aq0kg9kqvxk-nixos-system-nixos-26.05.20261015.26f4107`.
- Aktiviert: `/run/current-system` entspricht dem gebauten System; `powerdevilrc` zeigt direkt ins Checkout und `/etc/systemd/sleep.conf` enthält die konfigurierte Stunde sowie `HibernateOnACPower=false`. Der Benutzer bestätigt den Neustart von PowerDevil.
- Kombinierter Übergang und Deckelaktion noch nicht getestet. Kurzer Test mit temporärer Zwei-Minuten-Verzögerung in `docs/hibernate.md` dokumentiert; er blockiert den Zwischencommit nicht.

## zsh und Git

- Ausgewertet: Flake-Prüfung und NixOS-Toplevel erfolgreich. Die Login-Shell für `tobias` ist als zsh deklariert; gemeinsame Git-Einstellungen und private Host-Identität sind enthalten.
- Gebaut: vollständiges System `/nix/store/8dgmrn42z89dz5y96pqsffsipwa1ln7j-nixos-system-nixos-26.05.20261015.26f4107`.
- Geprüft: Syntax der nativen und erzeugten zsh-Konfiguration; interaktiver Start mit erzeugter Konfiguration und temporärem ZDOTDIR/History-Pfad. Completion, Autosuggestions, Syntaxhervorhebung, Alias und Git-Branch-Erkennung erfolgreich. Der noch nicht aktivierte native Symlink wurde für diesen Test durch den direkten Checkout-Pfad ersetzt.
- Git: erzeugte Konfiguration auf Name, E-Mail, Aliase, `init.defaultBranch` und `push.autoSetupRemote` geprüft.
- Aktiviert: noch nicht; kein Systemwechsel durch den Agenten.
- `origin` auf SSH umgestellt. Benutzer bestätigt hinterlegten öffentlichen Schlüssel und übernimmt wegen der Passphrase selbst Verbindungstest und Push; beides hier noch nicht bestätigt.

## Prompt und History-Tasten korrigiert; Push-Konflikt

Der Benutzer hat den zsh-/Git-Stand aktiviert (`/run/current-system` entspricht dem oben gebauten System). Beim ersten Push funktionierte die SSH-Authentifizierung, GitHub lehnte aber `rebuild/nixos-foundation` mit `directory file conflict` ab. Die vorhandene Remote-Referenz `origin/rebuild` erklärt die Namenskollision. Der lokale Branch wurde in `nixos-foundation` umbenannt; keine Remote-Referenzen gelöscht oder überschrieben.

Der zunächst neu geschriebene Prompt entsprach nicht der erwarteten bisherigen Umgebung. Deshalb wurde gezielt die native Powerlevel10k-Konfiguration aus dem Legacy-Checkout übernommen. Strg-P und Strg-N navigieren ausdrücklich in der History; der Vi-Modus bleibt vorerst zsh-intern.

- Ausgewertet: Flake-Prüfung und NixOS-Toplevel erfolgreich.
- Gebaut: vollständiges System `/nix/store/1n1r0q8byfa08inwx2nx0wkixqdi79ab-nixos-system-nixos-26.05.20261015.26f4107`.
- Geprüft: zsh-Syntax und Start mit Powerlevel10k/Legacy-Konfiguration; Strg-P/Strg-N im Vi-Eingabemodus korrekt gebunden.
- Aktiviert: diese Prompt-Ergänzung noch nicht. Push des umbenannten Branches bleibt beim Benutzer.

## Starship als gewählter Prompt

Auf Benutzerwunsch ersetzt ein separates Starship-Feature die kurzfristig übernommene Powerlevel10k-Konfiguration. Native TOML direkt ins Checkout verknüpft, zsh-Integration über Home Manager. Verzeichnis, Git-Branch/-Status, Nix-Shell und SSH-Hostname links; Fehlercode und Laufzeit rechts. Laufzeit ohne Mindestdauer einschließlich Millisekunden. Shell-Tastenkürzel bleiben erhalten; spätere Optimierungen und Alternativen in der Roadmap.

- Ausgewertet: Flake-Prüfung und NixOS-Toplevel erfolgreich.
- Gebaut: vollständiges System `/nix/store/h29f8g8bzai0ji1zihkzcp4gwf7jkr0i-nixos-system-nixos-26.05.20261015.26f4107`.
- Geprüft: Starship 1.25.1 rendert die native Konfiguration ohne Warnungen; Git-Branch, Fehlercode, 17 ms und 0 ms erfolgreich angezeigt. Native zsh-Konfiguration syntaktisch gültig.
- Aktiviert: noch nicht; kein Push durch den Agenten.

## Starship aktiviert; erste zusätzliche Desktop-Sitzung gebaut

Der Benutzer bestätigt den Starship-Prompt. `/run/current-system` entspricht dem oben gebauten Starship-System. Die Startdateien liegen unter `~/.config/zsh`; `~/.zshenv` leitet dorthin weiter, `ZDOTDIR` wird in der dortigen `.zshenv` gesetzt.

Für den nächsten separaten Schritt eingerichtet: Niri 26.04 aus System-Nixpkgs, Noctalia 5.3.0 aus dem vorhandenen Tools-Input, native Konfigurationsdateien, Niri-Session in SDDM, Xwayland-Satellite und fuzzel. Noctalia startet nur über Niri. UPower, Bluetooth und Power-Profiles-Daemon sind deklariert; Netzwerk und Audio verwenden die bestehende Konfiguration.

- Ausgewertet: Flake-Prüfung und NixOS-Toplevel erfolgreich.
- Gebaut: vollständiges System `/nix/store/kycgdxwiw213798kf7777mqvv0zzry3p-nixos-system-nixos-26.05.20261015.26f4107`.
- Geprüft: `niri validate --config modules/features/niri/config.kdl` und `noctalia config validate modules/features/noctalia/config.toml` erfolgreich. Die verwendeten IPC-Kommandos sind in der mitgelieferten CLI dokumentiert; Niri-Sitzungsdatei vorhanden.
- Aktiviert: neuer Desktop noch nicht; kein grafischer Sitzungsstart durch den Agenten. Login, Skalierung, Hardware, Portale und Lockscreen bleiben am Gerät zu testen.

## Erster Niri-Login und Fensterverhalten

Der Benutzer ist in Niri/Noctalia angemeldet. Auf Wunsch maximiert Super+F jetzt das Fenster mit sichtbarer Leiste, Super+Shift+F schaltet echtes Vollbild. Größenänderungsanimationen sind deaktiviert. Neue Firefox-Fenster starten gekachelt ohne wiederhergestellte Maximierung/Vollbild; die Ursache des vorherigen Startzustands wurde nicht abschließend nachgewiesen. Bei der Bestandsaufnahme belegte Firefox ungefähr die Bildschirmfläche abzüglich der Leiste.

- Native Niri-Validierung, Flake-Prüfung und NixOS-Toplevel-Auswertung erfolgreich; System-Derivation unverändert (`ikj327wxagxkqhpk6iskwdpv522lsnb4`). Kein neuer Systembuild oder Systemwechsel erforderlich.
- Das laufende Niri hat die native Datei laut Journal am 2026-10-19 um 00:37:36 neu geladen. Visueller Benutzertest der Änderungen steht aus.
- Gesten in Niri 26.04 sind im Eingabecode fest auf drei/vier Finger verteilt. Wünsche und Konflikt mit externen Listenern sind in der Roadmap dokumentiert; keine zusätzliche Gestensoftware oder Umbelegung von Super+J/K eingerichtet.

## Ghostty statt Konsole

Ghostty 1.3.1 und MesloLGS NF als ThinkPad-Home-Manager-Feature eingerichtet. Native Konfiguration direkt ins Checkout verknüpft, Niri-Terminalkürzel auf Ghostty umgestellt. Weitere gewünschte Arbeiten in der Roadmap erfasst.

- Ausgewertet: Flake-Prüfung und NixOS-Toplevel erfolgreich.
- Gebaut: vollständiges System `/nix/store/gavxi8pc6xzm7f0h0drqw445di2mrbjv-nixos-system-nixos-26.05.20261015.26f4107`.
- Geprüft: `ghostty +validate-config` für die native Datei erfolgreich; Niri-Konfiguration validiert.
- Aktiviert: noch nicht. Grafik, Schrift und Shell-Integration im neuen Terminal sind anschließend interaktiv zu prüfen.
