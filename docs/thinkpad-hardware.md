# ThinkPad: Grafik und Energiesparen

## Bestandsaufnahme am 2026-10-18

- Lenovo ThinkPad P1 Gen 4i, Modell 20Y4S0F300, BIOS 1.32.
- Intel-GPU an `0000:00:02.0`, PCI-ID `8086:9a60`, Treiber i915.
- NVIDIA-GPU an `0000:01:00.0`, PCI-ID `10de:249c`, bisher Treiber Nouveau.
- Das interne eDP-Display hängt an Intel. Externe Anschlüsse sind an beiden GPUs sichtbar; ihre praktische Nutzung wird mit angeschlossenem Monitor geprüft.
- 64 GiB RAM, bisher kein Swap; rund 941 GiB frei im verschlüsselten ext4-Root-Dateisystem.
- Aktuell angebotener RAM-Schlafmodus: `s2idle`. `deep` wird von der Firmware derzeit nicht angeboten und wird deshalb nicht erzwungen.

## NVIDIA und PRIME

`nvidia-prime` aktiviert NVIDIAs offene Kernelmodule und den dazugehörigen Userspace-Treiber aus dem fixierten System-Nixpkgs, aktuell Version 595.71.05. Der Branch heißt `stable`; ein Lockfile-Update kann auch die Treiberversion verändern. NixOS verhindert mit dieser Treiberauswahl das Laden von Nouveau.

Intel übernimmt reguläres Rendern für das interne Display. Programme lassen sich mit `nvidia-offload PROGRAMM` gezielt auf NVIDIA starten. CUDA-Anwendungen wählen die GPU über ihre Laufzeit; der Grafik-Offload-Wrapper allein richtet keine CUDA-Laufzeit ein. Diese folgt mit der AI-Umgebung.

Die PCI-Bus-IDs werden im Hostmodul gesetzt. Das Feature konfiguriert außerdem:

- DRM-Modesetting und 32-Bit-Grafikbibliotheken für spätere Spiele.
- Runtime-Energieverwaltung, damit NVIDIA bei geeigneter Hardware und ohne GPU-Last schlafen kann.
- Erhalt des Grafikspeichers über Suspend/Resume. NixOS wählt anhand der Treiberversion die passende Kernel-/systemd-Integration.
- Ein Verzeichnis auf der verschlüsselten SSD für temporär gespeicherte VRAM-Inhalte (`/var/lib/nvidia-sleep`).

NVIDIA kann bei laufenden CUDA-Aufgaben oder bei von ihr betriebenen externen Displays aktiv bleiben. Wiederholtes `nvidia-smi` kann sie ebenfalls aufwecken; damit keinen Idle-Verbrauch messen.

### Suspend-Test und gezielter Folgeversuch

Der erste Boot mit NVIDIA 595.71.05 war erfolgreich: Intel-/NVIDIA-Offload funktionierte, 16 GiB VRAM wurden erkannt und die NVIDIA-GPU erreichte im Leerlauf `runtime_status=suspended`.

Beim anschließenden Suspend am 2026-10-18 von 22:04 bis 22:20 trat beim Aufwachen ein GSP-Firmware-Absturz auf (`Xid 120`, danach `Xid 154`, GPU Reset Required). Der Desktop auf Intel kam zurück, aber `nvidia-smi` und NVIDIA-GLX-Offload funktionierten nicht mehr. Das war Suspend nach `s2idle`, noch kein Hibernate.

Aktiv war `UseKernelSuspendNotifiers=1`, der NixOS-Standard für diesen offenen Treiber. Als nächster einzelner Versuch schaltet das ThinkPad-Hostmodul auf den systemd-/procfs-Suspend-Pfad um: `kernelSuspendNotifier=false` aktiviert die NixOS-Dienste, und `NVreg_UseKernelSuspendNotifiers=0` stellt den Treiber ausdrücklich auf denselben Pfad. VRAM-Erhalt, Treiberversion und Runtime-Energieverwaltung bleiben erhalten. Das ist ein zu testender Workaround, keine bestätigte Behebung.

Nach Build und `sudo nixos-rebuild boot --flake .` neu starten. Vor dem nächsten Suspend prüfen:

```bash
nvidia-smi
grep UseKernelSuspendNotifiers /proc/driver/nvidia/params
ls -l /proc/driver/nvidia/suspend
systemctl cat nvidia-suspend.service nvidia-resume.service
```

Erwartet: funktionierende GPU, Parameterwert `0`, vorhandene procfs-Schnittstelle und die NVIDIA-Dienste. Danach Arbeit speichern, `systemctl suspend` ausführen und nach dem Aufwachen erneut `nvidia-smi` sowie `nvidia-offload glxinfo -B` testen. Für die anschließende Diagnose stehen `journalctl -b -u nvidia-suspend -u nvidia-resume -u systemd-suspend` und die Kernel-Logs bereit.

Ähnliche GSP-Suspend-Probleme sind [upstream für Treiber 595.71.05 dokumentiert](https://github.com/NVIDIA/open-gpu-kernel-modules/issues/1142), allerdings auf anderer Hardware und anderem Kernel. Daraus folgt keine sichere Diagnose für dieses Gerät. Vor Hibernate muss unser eigener Wiederholungstest erfolgreich sein.

### Zweiter Test fehlgeschlagen; nächster Test: grobe Runtime-Energieverwaltung

Auch mit `UseKernelSuspendNotifiers=0` schlug Resume fehl. Die NVIDIA-Suspend-/Resume-Dienste liefen erfolgreich; der Kernel meldete einen s2idle-Zyklus von 22:33:45 bis 22:34:35, anschließend erneut Xid 120 und `GSP boot failed at resume ... 0x62`. Der Benutzer beobachtete laufende Lüfter während der Schlafphase. Aus dem protokollierten s2idle-Zyklus allein lässt sich nicht ableiten, ob die Plattform ihren tiefsten S0ix-Stromsparzustand erreicht hat.

Die erfolglose Notifier-Änderung wird zurückgenommen. Als nächster Test verwendet das Hostmodul `finegrained=false` und ausdrücklich `NVreg_DynamicPowerManagement=0x01` (coarse-grained). Nur `finegrained=false` würde nicht genügen: Der NVIDIA-Standard kann auf Ampere-Laptops weiterhin die feine Runtime-Abschaltung aktivieren. Der Kernel-Suspend-Notifier wird wieder durch den unveränderten NixOS-Standard gewählt.

Ein [NVIDIA-Forenbericht mit RTX 3080 Mobile, Treiber 595.71.05 und gleichem Xid-/GSP-Fehler](https://forums.developer.nvidia.com/t/gsp-xid-120-panic-during-s2idle-suspend-with-nvreg-dynamicpowermanagement-0x02/369568) berichtet Erfolg mit `0x01`. Andere CPU/Plattform; es ist ein begründeter Test, keine bestätigte Lösung auf diesem ThinkPad. Grobe Runtime-Energieverwaltung kann die GPU länger aktiv halten und den Idle-Verbrauch erhöhen.

Nach erneutem Build, `sudo nixos-rebuild boot --flake .` und Neustart gelten für diesen Test die folgenden erwarteten Werte (sie ersetzen die Prüfwerte des vorherigen Versuchs):

```bash
grep -E 'UseKernelSuspendNotifiers|DynamicPowerManagement:' /proc/driver/nvidia/params
# UseKernelSuspendNotifiers: 1
# DynamicPowerManagement: 1
nvidia-smi
```

Danach Suspend und beide GPU-Prüfungen wiederholen. Noch kein Hibernate und kein Zwischencommit, bis das Schlafverhalten geklärt ist.

## Erster Start mit NVIDIA

Für den ersten Treiberwechsel die neue Generation für den nächsten Boot vorbereiten. So werden laufende Grafikprogramme bis zum Neustart nicht auf neue Treiberbibliotheken umgestellt:

```bash
cd ~/code/tobmoeller/dotfiles
sudo nixos-rebuild boot --flake .
```

Danach die Arbeit speichern und selbst neu starten. Die vorherige Generation bleibt im Bootmenü auswählbar. Nach dem Neustart im grafischen Terminal prüfen:

```bash
lspci -nnk -d 10de:
nvidia-smi
glxinfo -B
nvidia-offload glxinfo -B
nvidia-offload vulkaninfo --summary
```

Erwartet: NVIDIA-Kernel-Treiber statt Nouveau, funktionierendes `nvidia-smi`, Intel als normaler Renderer und NVIDIA beim Offload. Danach einen externen Monitor und gewöhnliches Suspend/Wiederaufwachen testen. Suspend bewusst nach Speichern der Arbeit auslösen, etwa über das Desktop-Menü.

Zum Prüfen des Idle-Zustands nach Ende der GPU-Programme etwas warten und lesen:

```bash
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
```

## Danach: Swap und Hibernate

Geplant ist eine 80-GiB-Swapdatei im bereits LUKS-verschlüsselten ext4-Dateisystem. Sie erfordert keine neue Partition und keine zusätzliche Zufallsverschlüsselung. Letztere würde die Wiederaufnahme nach einem Neustart verhindern.

Vor Hibernate müssen sowohl die Swapdatei als auch der Resume-Pfad im frühen Boot korrekt eingerichtet sein. Erst nach einem erfolgreichen manuellen Hibernate-/Resume-Test folgt `suspend-then-hibernate`: zunächst RAM-Schlaf, später Ausschalten mit auf SSD gesicherter Sitzung. Ausgangspunkt ist eine Stunde im Akkubetrieb; am Netz soll der Rechner im RAM-Schlaf bleiben.

Das bloße Setzen von `HibernateDelaySec` ändert einen normalen Suspend-Aufruf nicht in Suspend-then-Hibernate. Zuklappen und Desktop-Energieverwaltung werden deshalb ausdrücklich auf die passende Aktion eingestellt, sobald Hibernate getestet ist.

## Quellen

- [NVIDIA 595.71.05: Open Linux Kernel Modules](https://download.nvidia.com/XFree86/Linux-x86_64/595.71.05/README/kernel_open.html)
- [NVIDIA: Runtime D3 Power Management](https://download.nvidia.com/XFree86/Linux-x86_64/615.71.09/README/dynamicpowermanagement.html)
- [NVIDIA: Suspend/Hibernate und Grafikspeicher](https://download.nvidia.com/XFree86/Linux-x86_64/615.71.09/README/powermanagement.html)
- [systemd: Schlafmodi und HibernateDelaySec](https://www.freedesktop.org/software/systemd/man/latest/systemd-sleep.conf.html)
