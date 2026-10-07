# <TICKET> — Fragen an Tobias

<!--
Fragen an Tobias, offene und entschiedene, mit seinen Antworten. Nichts wird gelöscht oder gekürzt. Keine Antworten auf Rückfragen, keine technischen Fragen (die stehen in spec.md unter „Entscheidungen").
Antworten: in die Zeile „Antwort:" schreiben, dann `/work <TICKET>` im Worker oder `siehe fragen.md` an den Lead. Rückfragen beantwortet der Worker im Chat.
Entschieden: der Abschnitt bleibt ganz stehen; die Überschrift bekommt „— entschieden: <Option> (<Datum>)", die Zeile „Antwort:" die Antwort wörtlich mit Quelle („Antwort (Chat, <Datum>): …").
Frage geändert nach Rückfrage: die vorige Fassung bleibt wörtlich am Ende des Abschnitts in <details><summary>Fassung vom <Datum> (vor Rückfrage)</summary> … </details>.
Regeln: /work SKILL.md §4a. Beim Anlegen nur den Teil bis zum Beispiel übernehmen.
-->

---

<a id="frage-1"></a>
## Frage 1 · <Titel in wenigen Wörtern>

**Kurzfassung**

- <Problem in einem Satz, mit Umfang: was betroffen ist, was nicht>
- A: <Name> → <Folge> · B: <Name> → <Folge>
- Empfehlung: <Option>, weil <Halbsatz> · Risiko: <Risiko der Empfehlung>
- <optional: was nur vermutet ist, oder was du dafür tun musst>

**Details**

Problem: <Klartext, kurze Sätze>

Umfang: betroffen <…> · nicht betroffen <…>

Optionen:
- A · <Name> — <was sie tut> · Auswirkung: <…>
- B · <Name> — <was sie tut> · Auswirkung: <…>

Empfehlung: <Option>, weil <…> · Risiko: <…; bei Verlustpotenzial Beleg oder „nicht belegt">

Belege:
- <`Datei:Zeile` oder Ticketstelle>: <was es zeigt>
- Vermutet: <Annahme> (<wie man sie belegen würde>)

Antwort:

---

<!--
Beispiel (nicht übernehmen):

<a id="frage-1"></a>
## Frage 1 · Zähler nach Firmware-Update zurücksetzen?

**Kurzfassung**

- Nach einem Firmware-Update startet ein Kartenterminal oft mehrmals neu. Offen ist, ob der neue Neustart-Zähler dann bei 0 beginnt. Betrifft nur die Detailansicht, nicht Export oder Alarme.
- A: nie zurücksetzen → Zahl über die ganze Lebensdauer · B: bei Update zurücksetzen → Zahl seit dem letzten Update, braucht ein neues Feld
- Empfehlung: A, weil das Ticket „seit Inbetriebnahme" sagt · Risiko: nach Updates springt die Zahl, das kann wie eine Störung aussehen

**Details**

Problem: Ob Neustarts nach einem Update mitzählen, legen weder Ticket noch Code fest.

Umfang: betroffen ist nur die Anzeige in der Detailansicht · nicht betroffen: Sync der Kartenterminals, Alarme, Export

Optionen:
- A · nie zurücksetzen — ein Zähler, der nur wächst · Auswirkung: kein neues Feld
- B · bei Update zurücksetzen — merkt sich den Update-Zeitpunkt in einem neuen Feld · Auswirkung: die Zahl vor dem Update ist in der Anzeige weg

Empfehlung: A, weil das Ticket es so formuliert · Risiko: Sprünge nach Updates

Belege:
- Ticket, Beschreibung: „seit Inbetriebnahme"
- `app/Models/CardTerminal.php:41`: das Gerät speichert keinen Update-Zeitpunkt
- Vermutet: 3–5 Neustarts pro Update (ein Blick ins Geräte-Log würde es zeigen)

Antwort:

---

<a id="frage-2"></a>
## Frage 2 · Zähler auch im Export? — entschieden: A (2026-09-30)

<Kurzfassung und Details unverändert wie gestellt>

Antwort (Chat, 2026-09-30): A, Export bleibt wie er ist, der Support braucht die Zahl dort nicht
-->
