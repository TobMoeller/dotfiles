# Fingerabdruck

Der ThinkPad-Sensor `06cb:00f9` ist im fixierten libfprint 1.94.10 enthalten.
Das Feature installiert fprintd. SDDM kann per Finger anmelden; Noctalia v5
spricht fprintd direkt an. Sein PAM-Passwortpfad bleibt ohne Fingerabdruck-
Wartezeit. sudo, SSH und Polkit bleiben beim bisherigen Passwortverfahren.
LUKS beim Boot wird weiterhin mit dem Passwort entsperrt.

```bash
dotfiles-rebuild
fprintd-enroll -f right-index-finger
fprintd-verify
```

Beim Einlernen den Anweisungen folgen. Erst nach erfolgreicher Verifikation
Noctalia mit `Super+Alt+L` sperren und Finger sowie Passwort-Fallback testen.
SDDM-Anmeldung und Entsperren nach Suspend danach separat prüfen.
Falls die Noctalia-GUI den Wert überschreibt: Fingerabdruck unter Sicherheit /
Sperrbildschirm aktivieren. Einlernen und praktische Funktion stehen noch aus.

```bash
fprintd-list "$USER"
journalctl -b -u fprintd
```

SDDM wartet pro Versuch höchstens fünf Sekunden, bevor der normale Passwort-
pfad folgt. Fingerprint-Login entsperrt den Schlüsselbund nicht automatisch;
dieser kann nach einer Anmeldung ohne Passwort separat danach fragen.
