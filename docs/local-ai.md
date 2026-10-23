# Lokale KI

Der ThinkPad wählt das Home-Manager-Feature `local-ai` und seine CUDA-Pakete
explizit. Ollama läuft als Benutzerdienst auf `127.0.0.1:11434`; die API ist
nicht im Netzwerk freigegeben. Whisper startet nur bei Aufruf.

Ollama kommt aus `nixpkgs-tools` (unstable), aktuell 0.40.4 für Nimble.
Whisper und Aider bleiben im System-Paketsatz.

```bash
dotfiles-rebuild
systemctl --user status ollama
ollama run qwen3.5:9b
```

Ollama speichert Modelle unter `~/.local/share/ollama/models`, Whisper unter
`~/.local/share/whisper`. Die Gewichte sind veränderliche Daten außerhalb von
Nix und werden nicht durch Nix-GC entfernt. Modell-Tags können sich ändern;
`ollama list` zeigt die lokal verwendeten IDs. Downloads erfolgen ausdrücklich,
nicht bei jedem Rebuild. Erneuter Download bei Bedarf:

```bash
ollama pull qwen3.5:9b
ollama pull qwen2.5-coder:14b
mkdir -p ~/.local/share/whisper
cd ~/.local/share/whisper
curl -fL -o ggml-large-v3-turbo.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin
```

Ein Modell gleichzeitig, eine Anfrage parallel, standardmäßig 8192 Tokens
Kontext. Nach einer Minute ohne Anfrage wird das Textmodell entladen.
Clients können den Kontext überschreiben; größere Kontexte benötigen mehr VRAM.
Mit `ollama stop qwen3.5:9b` vor Gaming oder Whisper Speicher freigeben.

## Entscheidungen mit Nimble

Nimble benötigt mindestens Ollama 0.40.4 und wird über die Entscheidungs-API
angesprochen, nicht als normaler Chat:

```bash
ollama pull nimble:9b
curl http://127.0.0.1:11434/v1/systemone -H 'Content-Type: application/json' -d '{
  "model": "nimble:9b",
  "state": "Ich freue mich sehr auf den Hackathon!",
  "questions": {
    "stimmung": {
      "type": "choice",
      "instructions": "Welche Stimmung drückt der Text aus?",
      "criteria": {"positiv": "Freude oder Zuversicht", "negativ": "Ärger oder Traurigkeit"}
    }
  }
}'
```

Die Antwort enthält die gewählte Kategorie und Wahrscheinlichkeiten für die
vorgegebenen Kategorien. Die Beispielanfrage ist ein Funktionstest.

## Coding

Für Fragen reicht `ollama run`. Aider kann Dateien lesen und bearbeiten:

```bash
cd /pfad/zum/projekt
OLLAMA_API_BASE=http://127.0.0.1:11434 aider --model ollama_chat/qwen3.5:9b --no-auto-commits
```

Aiders native `~/.aider.model.settings.yml` ist direkt im Checkout bearbeitbar
und begrenzt den Kontext für beide Testmodelle auf 8192 Tokens. Beim ersten
Versuch mit einem kleinen Projekt beginnen und `ollama ps` prüfen.
Als separater Coding-Vergleich ist `qwen2.5-coder:14b` möglich (ca. 9 GB Download).

## Sprache zu Text

```bash
# Aufnahme mit Strg+C beenden; vorhandene Audiodateien gehen ebenfalls.
pw-record /tmp/diktat.wav
ffmpeg -i /tmp/diktat.wav -ar 16000 -ac 1 -c:a pcm_s16le /tmp/diktat-16k.wav
whisper-cli -m ~/.local/share/whisper/ggml-large-v3-turbo.bin -l de -f /tmp/diktat-16k.wav -otxt
```

Fachbegriffe lassen sich mit `--prompt 'Laravel, PHP, NixOS, GitHub'` vorgeben.
Das ist ein Erkennungshinweis; Identifier und Code-Syntax trotzdem prüfen.
Mikrofon-Shortcut, Texteingabe in andere Apps und Weboberfläche folgen separat.

## Prüfen

`ollama ps` zeigt die GPU-/CPU-Aufteilung. `nvidia-smi` zeigt GPU-Speicher und
Prozesse. Whisper protokolliert die CUDA-Geräte und die Backend-Auswahl beim
Start. Logs: `journalctl --user -b -u ollama`. Nach Suspend erneut prüfen.

Prüfstand 2026-10-23: Whisper 1.8.4 mit large-v3-turbo auf CUDA getestet;
öffentliche elfsekündige englische Testaufnahme korrekt transkribiert,
ca. zwei Sekunden einschließlich Modellladen. Kein Qualitätsbenchmark;
deutsche Aufnahmen und Fachsprache bleiben separat zu prüfen. Die SHA256 der
Gewichte stimmt mit dem veröffentlichten Git-LFS-Hash überein.

Heruntergeladene Ollama-Modelle: `qwen3.5:9b` (ID `56671c2ab938`) und
`qwen2.5-coder:14b` (ID `9ec8897f747e`).

Prüfstand 2026-10-24: vollständiger NixOS-Build und Flake-Prüfung erfolgreich.
Ollama 0.40.3 lädt beide Modelle bei 8192 Tokens vollständig auf die GPU
(`100% GPU`); kurze Coding-Antwort mit Qwen3.5 geprüft. Aider 0.86.1 hat mit
Qwen2.5-Coder eine absichtlich fehlerhafte Python-Funktion im temporären
Testverzeichnis korrigiert; Ergebnis mit positiven, negativen und Nullwerten
geprüft. Testserver danach beendet; dauerhafter Dienst noch nicht aktiviert.

Update 2026-10-24: Ollama 0.40.4 aus dem aktualisierten Tools-Input vollständig
gebaut, Flake-Prüfung erfolgreich. CUDA 12.9 stammt ebenfalls aus diesem Input.
Nimble 9B heruntergeladen und mit einer deutschen Choice-Frage über
`/v1/systemone` geprüft: Kategorie `positiv`, vollständig auf GPU geladen
(ca. 9,7 GB bei rund 8192 Tokens Kontext). Testserver beendet. Anschließender
Benutzer-Rebuild ist bestätigt: laufendes System entspricht dem geprüften Build,
der reguläre Ollama-Dienst meldet 0.40.4.

Quellen: [Ollama](https://docs.ollama.com/faq),
[Qwen3.5](https://ollama.com/library/qwen3.5:9b),
[whisper.cpp](https://github.com/ggml-org/whisper.cpp),
[Aider mit Ollama](https://aider.chat/docs/llms/ollama.html).
