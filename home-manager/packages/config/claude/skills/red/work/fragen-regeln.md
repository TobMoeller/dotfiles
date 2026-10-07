# /work — Fragen an Tobias (§4a–§4c)

Read on demand from `SKILL.md`: when an agent returns a question for
Tobias, when a gate with questions is drafted, when he answers, asks back
or opens a discussion. Section numbers are the ones `SKILL.md` cites.

## 4a. `fragen.md` — the questions to Tobias and his answers

`$store/fragen.md`, created from `fragen-template.md` next to this
SKILL.md. It holds **the questions the agents have for Tobias, open and
decided, with his answers** and nothing else: no answers to his
Rückfragen, no technical questions the agents decide (those are `T<n>`
lines under `## Entscheidungen` in `spec.md`, or in the `## Diagnose`, and
reach him in `handover.md`), no evidence beyond what the decision needs.
It is his record: he must be able to point back at the exact question
and answer a decision rests on. **A section he has seen is never deleted
or shortened.** Open = a section whose heading has no `— entschieden`;
only those go into a gate.

One section per question, `---` between sections, numbered once and never
renumbered (`F<n>` in `state.md` is the same n; gate, author and status
live in that index line, not in the section). Each section, short:

- `## Frage <n> · <Titel>`
- **Kurzfassung:** 3–5 bullets, the pillars of the decision (problem with
  scope, options with consequence, recommendation with its own risk). It
  goes into the gate verbatim.
- **Details**, about 25 lines at most: problem in plain words with its
  scope (what is affected, what is not) · the options with their effects ·
  the recommendation with reason and its own risk · `Belege:` as terse
  lines (`Datei:Zeile` or ticket passage), guesses marked `Vermutet:`.
- Options in Kurzfassung, Details and gate are identical: same set, same
  letters, same names.
- One line `Antwort:`, empty: Tobias writes there.

A decided section stays complete where it is. Its heading gets the
status: `## Frage <n> · <Titel> — entschieden: <Option> (<Datum>)`. Its
`Antwort:` line holds Tobias' answer **verbatim** with source and date:
`Antwort (Chat, <Datum>): <sein Text wörtlich>`, or, written in the
document, his text stays as he wrote it and gets ` (Dokument, <Datum>)`
appended. A bare `ok` is recorded as `ok (= Empfehlung <Option>)`.

- **Authors:** the analyst (fachliche spec questions), the auditor
  (sections it hands to Tobias, `ESK` questions), the writer (`ABNAHME`
  questions). `spec.md`, `plan.md` and `handover.md` only link
  (`fragen.md#frage-<n>`), they never discuss a question.
- **This session** writes in `fragen.md` only the status in the heading
  of a decided section and the recorded answer in its `Antwort:` line;
  the content belongs to the author. It never empties or rewrites what
  Tobias wrote.

**Writing rules** — for every text Tobias reads (`fragen.md`, the gate,
the answer to a Rückfrage, `handover.md`). Analyst, auditor and writer
follow them; the plan-verifier checks them (§4c):

- No abbreviation, error code, ticket number or class name without plain
  words beside it: „Fremdschlüssel-Fehler der Datenbank (MySQL 1452)",
  not „1452".
- Scope stated: what is affected and what is not („nur der Mandanten-Sync,
  nicht der übrige Konnektor-Sync").
- Blank lines between blocks, lists instead of running text, short
  sentences.
- Evidence and guess always apart: a Beleg is `file:line`, ticket text,
  log line or query result; a guess is marked `Vermutet:` (with how it
  could be proven).
- Every recommendation names its own risk.
- Loss potential (a lock that drops or skips jobs, deletes, overwrites,
  data-removing migrations): the problem it solves needs real evidence (a
  log, production data, a reproducing test, a code path with `file:line`
  that shows it happens). Without it the recommendation says „nicht
  belegt" in its risk, and the option without loss potential is the
  default.

**Reading answers.** Both ways count, for every gate with questions:

- **Chat** (`ok`, `<n>: …`, typed here or relayed by the lead).
- **Document** (`siehe fragen.md`, or `/work <TICKET>` without argument
  while `gate: open`): read the last `Antwort:` line of every open
  section. Empty → the question stays open; in the document no answer is
  not `ok`. No answer anywhere → print the gate again and stop. A
  Rückfrage written there stays: append ` (Dokument, <Datum>, Rückfrage)`
  to it and add a fresh empty `Antwort:` line below.
- Then per answer: **decision** (an option, `ok`, text that settles it) →
  status into the section's heading and the answer recorded verbatim in
  its `Antwort:` line (above), one `## Entscheidungen` line in
  `state.md` (Quelle: Tobias) and one log line, tick in `## Offene Fragen`,
  the decision as one line under `## Entscheidungen` in `spec.md` (bug:
  under `## Diagnose` in `plan.md`; a deviating answer reaches the spec
  through the analyst's re-brief), then the gate's phase rule (SPEC: §3).
  **Rückfrage** → §4b. Open questions left → the gate block is rewritten
  with only those and sent again.

## 4b. Rückfragen and discussion in this pane

**Rückfrage** (Tobias asks back about a question): not a new round, no
limit, no `nein`. **The answer goes to him in the chat, never into
`fragen.md`**, and his Rückfrage is never turned into a new question to
him.

- Answer directly when `fragen.md`, `spec.md` or `state.md` hold the
  answer. Otherwise brief the section's author (the auditor for its own
  sections, not counted against `auditor:`; otherwise the analyst) with
  the section path and the Rückfrage verbatim; it returns `ANTWORT:` and
  says whether the question itself changes.
- Deliver the answer where the Rückfrage came from: printed here, or via
  `SendMessage` to the lead (§0). Plain words under the writing rules,
  guesses marked `Vermutet:`, at most about 10 lines.
- **Only when the question itself changes** (its options, its
  recommendation, its scope): the author rewrites the section and keeps
  the previous wording at its end as `<details><summary>Fassung vom
  <Datum> (vor Rückfrage)</summary> … </details>`, verbatim, never
  dropped; `plan-verifier` **Modus: fragen** on that section and the
  redrafted gate (§4c); the new Kurzfassung goes into the gate, which is
  sent with the answer. Otherwise `fragen.md` and the gate stay as they
  are.
- One log line `gate · Rückfrage zu Frage <n> · im Chat beantwortet [·
  Frage geändert]`. `spec.md` changes only after the decision.

**Discussion.** From the **second** Rückfrage on the same question (count
the log lines), or when Tobias asks for it (`diskussion <n>`, here or via
the lead), the question moves to this pane:

- Frontmatter `discussion: <n>`, log line. The `## Gate` block stays as
  written; the lead gets only the pointer line (§0) and stays out until
  the next gate or done.
- Tobias types here without `/work`. Answer each message as a Rückfrage
  above: from the files directly, or through the section's author
  (continue it with `SendMessage` when its agent id from this session is
  known, else a fresh brief with the section path and his messages so
  far). **Answers stand only in this chat**, never in `fragen.md`; the
  section is rewritten only when the question itself changes (previous
  wording kept as above), and then re-checked (§4c).
- End each reply with the state line and `Entscheiden: <n>: <Option> ·
  ok`. Ending the turn with this plain text is allowed here: the gate is
  open, nothing advances without his decision. Never `AskUserQuestion`;
  never read a decision into a tone („klingt gut" → ask in one line
  whether that means option X).
- A decision (`<n>: <Option>`, `ok`, `entschieden: <Text>`) → clear
  `discussion:`, handle it per §4a, continue the pipeline; the next gate
  or done goes to the lead as usual. Other open questions of the gate can
  be answered here or at the lead.

## 4c. Question check — one pass, for form and class, not for permission

Tobias wants to intervene early, and he wants questions that are worth
his time. Both at once works through **classes**, not through rounds:

| Klasse | Was sie meint | Geht an |
|---|---|---|
| `Lücke` | das Ticket lässt etwas offen oder widerspricht sich; die Spec musste raten | Tobias |
| `Aufwand` | eine Vorgabe kostet weit mehr als das Ticket vermuten lässt, oder eine einfachere, elegantere Lösung erfüllt den Zweck | Tobias |
| `Nutzer` | eine Vorgabe ist für die Nutzer oder den Betrieb ungünstig | Tobias |
| `Daten` | die Lösung ruht auf einer Annahme über echte Daten (gibt es die Fälle, wie viele, welche Form); Statement liegt bei | Tobias, vor dem Bauen |
| `Produkt` | Verhalten, das weder Ticket noch Code festlegen und das Nutzer sehen | Tobias |
| `technisch` | zwei tragfähige Designs, Code und Regeln entscheiden nicht | Auditor |

Before any hard gate with questions (`SPEC`, `ABNAHME`, `ESK`), and after
a section was replaced, **one** `plan-verifier` in **Modus: fragen**: the
`fragen.md` path, the section numbers, the drafted `## Gate` block in
`state.md`. It does not see the author's report. Per question it checks:

- (a) the class is right: a `technisch` question dressed as `Produkt` goes
  to the auditor; a `Lücke`/`Aufwand`/`Nutzer`/`Daten`/`Produkt` question
  stays for Tobias even when the verifier would decide it differently;
- (b) the cited Belege hold (spot check against the code or the ticket);
- (c) the problem is shown or marked: a Beleg, or the line `Vermutet:`
  with how it could be checked — an unmarked guess fails, a marked one
  passes (Tobias judges guesses himself);
- (d) the options are complete, and identical in Kurzfassung, Details and
  the gate draft (set, letters, names); for a scope question, „complete"
  means every sibling gap the analyst's sweep found (the `out:` line of
  the spec or Diagnose) is either inside an option or named as left out
  with its reason — a question about „alle drei Filter" while the sweep
  lists four fails here;
- (e) the writing rules hold (§4a).

Handling, **one round only**:

- (a) `technisch` → to the auditor's `T<n>` list; the section goes.
- (b), (c), (d), (e) → back to the author once with the Befunde; the fixed
  section goes into the gate without a second check. The verifier never
  removes a question of the five Tobias classes, and the auditor never
  decides one.
- The writer's and the auditor's own questions: same rules.

Every question that moved or was fixed: tick in `## Offene Fragen`, log
line `fragen · Frage <n> · <Klasse> · <an Tobias | an Auditor | Form
korrigiert>`. No question for Tobias left and nothing `vor dem Bauen` → the
gate's no-stop rule (SPEC: §3).

Every removed or decided question: tick in `## Offene Fragen`, `##
Entscheidungen` line with its Quelle, log line `fragen · Frage <n> nicht
an Tobias · <Kriterium> · <was stattdessen>`; it reaches him in
`handover.md`. No question left and nothing `vor dem Bauen` → the gate's
no-stop rule (SPEC: §3).

