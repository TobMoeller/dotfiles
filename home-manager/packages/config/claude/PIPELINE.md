# Die Ticket-Pipeline

Das ist die Beschreibung des Flows für Menschen. Die ausführbaren Fassungen
sind die Skills `/lead`, `/work`, `/day` und die Agent-Profile unter
`~/.claude/agents/`. Wenn sich etwas widerspricht, gilt der Skill, und diese
Datei wird nachgezogen.

## In einem Satz

Ich (Tobias) spreche mit `/lead` darüber, welche Tickets heute laufen. Jedes
Ticket bekommt einen Worktree und eine eigene Claude-Session, in der `/work`
die Arbeit an Spezialisten delegiert, jeden Schritt unabhängig prüfen lässt
und regulär nur einmal auf mich wartet: bevor irgendetwas das Gerät
verlässt (Abnahme). Vor dem Bauen hält sie nur, wenn eine fachliche Frage
offen ist, die kein Agent aus Code und Doku beantworten kann.

## Die drei Ebenen

| Ebene | Wo | Was sie tut | Was sie nie tut |
|---|---|---|---|
| `/lead` | eine Session pro Tag, herdr-Space `lead`, cwd `work-log` (`wt lead`) | Tagesplan, Worker starten, Gate-Nachrichten empfangen und Antworten weiterreichen, „done" nachprüfen, Tagesnotiz führen | Code, Reviews, Jira-Schreibzugriff, Permission-Prompts beantworten |
| `/work` (Worker) | eine Session pro Ticket, im Worktree | State-Maschine: liest und schreibt `state.md`, brieft Agents, committet verifizierte Schritte, meldet Gates an den Lead | selbst Code lesen oder ändern |
| Spezialisten | Subagents des Workers | je eine Aufgabe mit festem Ergebnisblock | Zustand halten, miteinander reden |

Lead und Worker sind getrennte Claude-Sessions und sprechen über
`SendMessage` miteinander (`ListAgents` zeigt die Namen). Der Lead schreibt
seinen Namen beim Start nach `work-log/.lead-session`; ein Worker schickt
dorthin jeden Gate-Block und die Done-Zeile. Der Lead antwortet mit
`/work RTM-xxxx <Antwort>` als Nachricht an den `session_name` aus der
`state.md`. herdr bleibt die Sicht von außen (idle, working, blocked) und
der Ort, an dem ich Permission-Prompts beantworte.

Der Lead läuft auf Fable (er spricht mit mir und urteilt; `wt lead` startet
ihn mit `--model fable`, Override `WT_LEAD_MODEL=opus`). Die Spezialisten
(alle Opus 5.5, Auditor auf Fable):

| Agent | Aufgabe | Gibt zurück |
|---|---|---|
| `analyst` | Ticket verstehen, Code lesen, Spec schreiben, echte Fragen finden (technische in die Spec, fachliche in `fragen.md`), Aufgaben für mich benennen, meine Rückfragen beantworten (Antwort nur im Chat) | `spec.md`, `fragen.md`, DoD, TLDR |
| `planner` | Spec → `plan.md` mit kleinen Schritten, je ein Test und ein Commit | `plan.md` |
| `plan-verifier` | drei Modi: Spec gegen Ticket, Code und Regeln prüfen, Fragen einordnen (SPEC-Prüfung) · jede Frage an mich prüfen, bevor sie mich erreicht (Fragen-Prüfung) · Plan gegen Spec, DoD, Regeln und Code prüfen | pass / fail / unsicher · Fragen fachlich/technisch · pro Frage pass/fail |
| `implementer` | genau einen Plan-Schritt bauen, Checks grün, nicht committen | Diff, Checks |
| `step-verifier` | drei Modi: ein Schritt · ganzer Branch · Review-Befunde widerlegen (in `/review` als Über-Review: zusammenführen, widerlegen, Schwere setzen) | pass / fail / unsicher · WIDERLEGT-Liste |
| `reviewer` | unabhängiger Reviewer des ganzen Branches (zwei parallel, drei bei L; drei in `/pre-review` und `/review`) | Befunde |
| `writer` | `handover.md`, offene Abnahme-Fragen in `fragen.md`, PR-Titel (kein Body), Jira-Kommentar in der `comment`-Stimme | Texte |
| `auditor` | Schiedsrichter bei Konflikt oder Unsicherheit, maximal zweimal pro Ticket; dazu einmal pro Spec-Runde für die technischen Fragen und für Fragen, die die Fragen-Prüfung nicht bestehen; beantwortet Rückfragen zu seinen eigenen Fragen (nur im Chat) | A / B / anders / Tobias; Urteile in der Spec unter Entscheidungen, Fragen an mich in `fragen.md` |

## Die Phasen

```
assess+spec ──SPEC──▶ plan ──▶ implement ──▶ verify ──CHECKS──▶ review ──▶ accept ──PR──ABNAHME──▶ done
   analyst            planner    implementer    step-verifier     reviewer ×2   writer
   plan-verifier      plan-      (+ step-       (Modus branch)    step-verifier plan-verifier
   (Modus spec)       verifier   verifier       ↺ Nacharbeit      (widerlegen)  (Modus fragen)
   auditor (techn.)              bei M, L)                        ↺ Nacharbeit
   plan-verifier
   (Modus fragen)

SPEC hält nur bei einer geprüften fachlichen Frage; sonst läuft es durch bis PR.
```

1. **assess + spec.** Der Analyst liest Ticket und Code und schreibt
   `spec.md` (bei Größe S zehn Zeilen, bei Bugs eine Diagnose in
   `plan.md`). Technische Fragen stehen dort unter „Entscheidungen". Nur
   die fachlichen Fragen, die Code, Doku und Ticket nicht beantworten,
   kommen nach `fragen.md`, je Frage ein kurzer Abschnitt. Dazu Aufgaben,
   die nur ich erledigen kann.
2. **SPEC-Prüfung.** Ein Plan-Verifier im Modus spec prüft die Spec blind
   gegen Ticket, Code und Regeln und ordnet die Fragen ein (zwei Runden,
   dann Auditor). Technische Fragen entscheidet der Auditor in einem
   Aufruf. Bleibt eine fachliche Frage, prüft ein Plan-Verifier im Modus
   fragen sie, bevor sie mich erreicht (siehe unten). Bleibt keine
   geprüfte fachliche Frage und keine Aufgabe „vor dem Bauen" offen, geht
   es ohne Halt in die Planung; Prüfung und Ergebnis stehen im Log. Sonst
   hält die Pipeline am SPEC-Gate.
3. **plan.** Planner schreibt die Schritte, Plan-Verifier prüft sie blind.
   Zwei Runden, dann Auditor.
4. **implement.** Pro Schritt: Implementer baut und testet, bei M und L prüft
   der Step-Verifier blind (drei Runden), dann staged und committet der
   Worker den Schritt. Bei S entfällt der Verifier pro Schritt.
5. **verify (CHECKS).** Step-Verifier im Branch-Modus: jedes DoD-Item hat
   einen Nachweis, keine Datei außerhalb des Plans, Tests der berührten
   Klassen und ihrer Aufrufer grün. Zwei Runden, Nacharbeit dazwischen.
6. **review.** Zwei Reviewer (drei bei L oder auf Wunsch), blind zueinander.
   Ihre Befunde werden von einem Step-Verifier im Widerlege-Modus gegen den
   Code geprüft. Was übrig bleibt, wird ein Nacharbeit-Schritt;
   Ermessensfragen landen in `## Offene Fragen`.
7. **accept (PR, dann ABNAHME).** Der Writer schreibt `handover.md` und offene
   Abnahme-Fragen nach `fragen.md`; die Fragen gehen durch die
   Fragen-Prüfung. Dann hält der Worker kurz am Gate PR: Er bittet mich,
   den Branch zu pushen und den PR nach `develop` ohne Beschreibung
   anzulegen (Befehl und Titel stehen im Gate). Das ist nicht Teil der
   Abnahme, sondern nur meine Review-Fläche in Gitea. Nach `pr da` prüft
   er Branch und PR nur lesend, dann kommt ABNAHME, und ich entscheide.
   Dort sehe ich auch zum ersten Mal, was die Agents in der Spec-Phase für
   mich entschieden haben, und was ich vor dem Deploy noch tun muss.

**Nacharbeit** ist immer dasselbe: ein angehängter Schritt `### N+k.
Nacharbeit <Quelle>` in `plan.md`, der durch die normale Implement-Schleife
läuft. Egal ob die Quelle CHECKS, ein Review-Befund oder meine Notiz ist.

## Die Gates

Ein Gate ist ein Block `## Gate` in der `state.md` des Tickets plus ein
beendeter Turn. Kein Dialog. **Beantwortet wird im Ticket-Tab:** der Worker
druckt den Block in seinem Space, dort antworte ich mit `/work RTM-xxxx
<Antwort>`, frage nach, diskutiere, oder schreibe die Antwort in `fragen.md`
und sage `siehe fragen.md`. Der Lead bekommt nur eine Zeile (Gate offen,
Gate beantwortet, done) für die Tagesnotiz und sagt mir, in welchem Space
die Antwort erwartet wird. Antworte ich trotzdem beim Lead, reicht er die
Antwort weiter. `wl RTM-xxxx` zeigt den offenen Block, `wl --open` alle.

**Welche Fragen mich erreichen.** Jede Frage trägt eine Klasse. Fünf
Klassen gehen immer an mich, nach genau einer Prüfung ihrer Form (Beleg
vorhanden oder als Vermutung markiert, Optionen vollständig, Schreibregeln),
nie nach Runden, in denen Agents entscheiden, ob ich sie sehen darf:

| Klasse | Bedeutung |
|---|---|
| `Lücke` | das Ticket lässt etwas offen oder widerspricht sich, die Spec musste raten |
| `Aufwand` | eine Vorgabe kostet weit mehr als das Ticket vermuten lässt, oder eine einfachere Lösung erfüllt den Zweck |
| `Nutzer` | eine Vorgabe ist für Nutzer oder Betrieb ungünstig |
| `Daten` | die Lösung ruht auf einer Annahme über echte Daten; das Statement liegt bei, Antwort vor dem Bauen |
| `Produkt` | Verhalten, das weder Ticket noch Code festlegen und das Nutzer sehen |

Die sechste Klasse, `technisch` (zwei tragfähige Designs), entscheidet der
Auditor. Was mich nicht erreicht: unmarkierte Vermutungen und als Produktfrage
verkleidete Designfragen.

| Gate | Art | Wann | Was ich entscheide | Antwort |
|---|---|---|---|---|
| **SPEC** | weich (Spec-Prüfung durch Agents gegen S1–S6); hart, sobald eine Frage der fünf Klassen oder eine Aufgabe „vor dem Bauen" offen ist | nach assess+spec | die Fragen an mich, in einem Rutsch | `ok` (alles wie empfohlen) · `1: <Option oder eigener Text> 2: <…>` (abweichend, Rückfrage oder Kontext; Rest wie empfohlen) · `siehe fragen.md` · `nein: <Notiz>` · jeweils `manual` anhängen = ich committe selbst |
| **CHECKS** | weich | nach implement | nichts, der Branch-Verifier entscheidet | keine, nach zwei Fehlrunden wird daraus LIMIT |
| **PR** | hart, kurz, nicht Teil der Abnahme | nach review, `handover.md` liegt vor; nach jeder Nacharbeit erneut (dann nur Push) | nichts, ich pushe und lege den PR an | `pr da` (Worker prüft Branch und PR lesend, trägt `pr:` ein, dann ABNAHME) · `ohne pr` · `parken` |
| **ABNAHME** | hart, immer | nach PR | abnehmen oder zurückschicken | `abnehmen` (nackter PR-Link als Jira-Kommentar ohne Prompt; der PR bleibt offen, mergen tue ich) · `abnehmen ohne-jira` · `nacharbeiten <Notiz>` (`siehe PR` = meine Kommentare im PR) · `parken` · offene Fragen wie bei SPEC |
| **ESK** | hart | der Auditor sagt „Tobias" und die Frage besteht die Fragen-Prüfung | die eine Frage, die kein Agent aus Code und Doku klären konnte | freier Satz · `siehe fragen.md` · `diskussion 1` |
| **LIMIT** | hart | ein Rundenlimit ist erschöpft | wie weiter | `redo <phase>` · `park <Notiz>` · freier Satz als Entscheidung |

**Fertig-Kriterien und Befund-Register.** Was ein Artefakt erfüllen muss,
steht in `~/.claude/skills/red/work/kriterien.md` (S1–S6 Spec, P1–P6 Plan,
I1–I5 Schritt, B1–B5 Branch), nicht im Kopf des Verifiers. In Runde 1
prüft der Verifier jede Zeile mit ja oder nein und führt alles auf, was ihm
auffällt; ein Nein ist ein Befund, alles andere ein Hinweis, der mitgegeben
wird und keine Runde kostet. Jeder Befund bekommt eine Id im Register
`pruefung/befunde.md` und wird fortan nur noch über die Id angesprochen:
der Autor antwortet `umgesetzt` oder `zurückgewiesen: <Beleg>`,
Zurückweisungen gehen gesammelt an den Auditor, dessen Urteil ist final und
steht im Register. Runde 2 prüft die offenen Ids nach, nicht das Dokument
neu. Kippt dasselbe Kriterium ein zweites Mal, entscheidet der Auditor
statt einer dritten Runde. Entschiedene Ids tauchen in keiner späteren
Prüfung wieder auf, außer mit neuem Beleg als neue Zeile.

Rundenlimits: Spec-Prüfung 2 · Plan 2 · pro Schritt 3 (nur M, L) · CHECKS 2
· Auditor 2 pro Ticket für Konflikte (der geplante Aufruf für die
technischen Spec-Fragen zählt nicht mit) · nach jedem Konflikt-Urteil genau
eine weitere Verifier-Runde · Rückfragen von mir ohne Limit (ab der
zweiten zur selben Frage geht die Diskussion in den Worker).
**Commit-Modus.** `commits: auto` ist der Default aus der Vorlage und meine
stehende Entscheidung: der Worker committet jeden verifizierten Schritt.
Abwählen pro Ticket mit `/work RTM-xxxx commits manual`, mit `manual` in
einer Gate-Antwort oder im Start-Prompt über den Lead („ich committe
selbst"). Zurück nur mit `commits auto` von mir.

### So sieht ein Gate aus

Im Chat druckt der Worker das Gate als normales Markdown (fette Kopfzeile
mit Gate, Ticket und Uhrzeit, TLDR als Absatz, Fragen mit fettem Titel,
Antworten als Liste mit je einem Befehl pro Zeile), nie in einem
Code-Block: Claude Code zeigt Code-Blöcke einfarbig und ohne Formatierung.
In `state.md` steht derselbe Inhalt in der Dateiform darunter.

Jeder Gate-Block (in `state.md` und als Nachricht an den Lead) ist in 30
Sekunden entscheidbar, in einfachem Deutsch, ohne Klassennamen und Codes
oberhalb der Details, höchstens 20 Zeilen, Leerzeilen zwischen den Blöcken:

```
SPEC · <Datum Uhrzeit>

TLDR: <ein Satz: das Problem mit Umfang und was gebaut wird>

Frage 1 · <Titel>
- <Kurzfassung wörtlich aus fragen.md, 3–5 Stichpunkte: Problem, Optionen, Empfehlung mit Risiko>
→ fragen.md#frage-1

Für dich zu tun: <nur was nur ich kann, mit „vor dem Bauen" / „vor dem Deploy">

Antwort: <eine Zeile, jede Antwort mit ihrer Folge>
Details: <eine Zeile: Größe, Branch, Pfad zu fragen.md, Hinweise>
```

PR, ABNAHME, ESK und LIMIT nutzen dieselbe Form (PR ohne Fragen, nur
Push-Befehl und PR-Titel unter „Für dich zu tun"; ABNAHME aus `handover.md`
und den Abnahme-Fragen in `fragen.md`; LIMIT mit „Wie weiter?" direkt im
Block, Belege darunter in `state.md`).

### Fragen, Antworten, Rückfragen

`fragen.md` im Ticket-Ordner ist nur dafür da, mir Fragen zu stellen, und
hält fest, was ich darauf geantwortet habe. Dort stehen die Fragen der
Agents an mich, offene und entschiedene, sonst nichts: keine Antworten auf
meine Rückfragen, keine technischen Fragen, die Agents
selbst entschieden haben (die stehen in der Spec unter „Entscheidungen"
und im Log und erreichen mich in `handover.md`).

Pro Frage ein kurzer Abschnitt, Trennlinie dazwischen (Vorlage
`skills/red/work/fragen-template.md`):

- `## Frage n · <Titel>`
- **Kurzfassung:** 3–5 Stichpunkte, die Eckpfeiler der Entscheidung,
  wörtlich auch im Gate.
- **Details:** Problem in Klartext mit Umfang · Optionen mit Auswirkungen ·
  Empfehlung mit Grund und eigenem Risiko · knappe Belegzeilen
  (`Datei:Zeile` oder Ticketstelle), Vermutungen als solche markiert.
  Höchstens etwa 25 Zeilen.
- Die Optionen sind in Chat und Datei identisch: gleiche Menge, gleiche
  Buchstaben, gleiche Namen.
- `Antwort:` leer, hier schreibe ich hinein.

Eine Frage, die ich gesehen habe, wird nie gelöscht oder gekürzt; ich muss
mich später auf genau diese Frage und meine Antwort beziehen können. Bei
der Entscheidung bekommt die Überschrift den Status `— entschieden:
<Option> (<Datum>)`, und in der Zeile `Antwort:` steht meine Antwort
wörtlich mit Quelle (`Antwort (Chat, <Datum>): …`; im Dokument bleibt mein
Text stehen). Zusätzlich steht die Entscheidung im Log der `state.md` und
in der Spec. Ins Gate kommen nur die offenen Abschnitte.

**Fragen-Prüfung.** Keine Frage erreicht mich ungeprüft. Vor jedem Gate
mit Fragen (SPEC, ABNAHME, ESK) prüft ein Plan-Verifier im Modus fragen
jede Frage: (a) ist sie wirklich fachlich, also nicht aus Code, Doku oder
Ticket beantwortbar, (b) stimmen die Belege, (c) ist das Problem real
belegt und nicht ausgedacht, (d) sind die Optionen vollständig und in
Chat und Datei identisch, (e) sind die Schreibregeln eingehalten. Fällt
eine Frage durch, kommt sie nicht zu mir: aus Code beantwortbar → der
Analyst entscheidet sie; ausgedacht → Risiko in der Spec oder weg; sonst
einmal Nachbesserung, danach entscheidet der Auditor. Das gilt auch für
die Fragen des Writers und des Auditors.

Antworten gehen beide Wege: im Chat (direkt oder über den Lead) oder im
Dokument in der Zeile `Antwort:`, dann `/work RTM-xxxx` bzw. `siehe
fragen.md` an den Lead. Im Dokument heißt eine leere Antwort „noch
offen", nicht „ok".

Eine **Rückfrage** öffnet keine neue Runde. Die Antwort bekomme ich
direkt im Chat, im Worker oder über den Lead; sie wird nicht in
`fragen.md` geschrieben, und meine Rückfrage wird nie zu einer neuen
Frage an mich. Nur wenn sich dadurch die Frage selbst ändert (Optionen,
Empfehlung, Umfang), wird ihr Abschnitt neu geschrieben; die vorige
Fassung bleibt wörtlich darunter eingeklappt stehen. Er wird neu
geprüft, und die neue Kurzfassung kommt ins Gate. Das Gate bleibt offen,
bis ich entscheide. Ab der **zweiten Rückfrage** zur selben Frage, oder
wenn ich `diskussion <n>` sage, wandert die Frage in den Worker-Space: der
Lead meldet nur noch „Diskussion im Worker · Space X (wt → wählen)" und
hält sich raus, bis das nächste Gate oder done kommt. Im Worker schreibe
ich einfach drauflos; die Antworten stehen nur im Chat, und er läuft erst
weiter, wenn ich entschieden habe.

**Schreibregeln** für alles, was ich lese (`fragen.md`, Gate,
`handover.md`):

- keine unerklärten Kürzel, Fehlercodes oder Klassennamen, immer Klartext
  daneben („Fremdschlüssel-Fehler der Datenbank (MySQL 1452)")
- Umfang nennen: was betroffen ist und was nicht
- Leerzeilen zwischen Blöcken, Listen statt Fließtext, kurze Sätze
- Evidenz und Vermutung immer getrennt
- jede Empfehlung nennt ihr eigenes Risiko
- Eingriffe mit Verlustpotenzial (Locks, die Jobs verwerfen; Löschungen)
  brauchen echte Evidenz, sonst steht „nicht belegt" als Risiko da

Der Plan-Verifier prüft diese Regeln in der Fragen-Prüfung mit.

## Was ohne mich passiert und was nicht

Ohne Prompt: lesen, Tests, Lint, Edits im Worktree, `git add`, `git commit`
nach verifiziertem Schritt (wenn `commits: auto`; die Message ist genau die
Zeile aus `plan.md`, ohne Trailer), Subagents starten, Nachrichten zwischen
Lead und Worker, der eigene Compose-Stack, Jira-Schreibzugriffe (Kommentar,
Transition, Felder, neues Ticket, Verknüpfung), die ich im Chat angefordert
habe oder die der Schritt vorsieht (der nackte PR-Link bei ABNAHME): meine
Anweisung ist die Freigabe, ein zweiter Prompt bringt nichts.

Immer mit Prompt im Worker-Space (das ist der Zweck, nicht ein Fehler):
jeder Schreibzugriff auf Gitea und Confluence außerhalb der Pipeline,
`wt rm`/`wt main`/`wt back`, `docker compose down` mit Volumes,
Branch löschen, Dateien unter `.claude/` oder `.env` in einem Worktree.
`rm` fragt nicht mehr, der Hook dafür war nur Arbeit.

Nur ich: pushen und den PR anlegen (der Worker fordert das am Gate PR an
und prüft danach nur lesend), und **mergen, immer**, auch nach der
Abnahme. Ein Push auf einen beliebigen Branch, auch `develop`, ist ein
Merge in anderer Form, deshalb pusht die Pipeline gar nicht.

Nie: `sudo`, Force-Push, `migrate:fresh`, `db:wipe`, `.env` oder
Credentials lesen. Die Hooks `bash-guard.sh` und `commit-guard.sh`
erzwingen das unabhängig vom Permission-Modus.

## Dateien pro Ticket

`~/code/knowledge/work-log/<repo>/<TICKET>/`

| Datei | Schreibt | Inhalt |
|---|---|---|
| `state.md` | `/work` | Frontmatter (phase, gate, step, round, commits, reviewers, session, …), `## Gate`, `## DoD`, `## Entscheidungen`, `## Offene Fragen` (fachlich/technisch), `## Für Tobias`, `## Commits`, `## Log` |
| `spec.md` | Analyst; Auditor und `/work` tragen Entscheidungen ein | die Spec, bei S kurz; technische Fragen und alle Entscheidungen unter „Entscheidungen"; fachliche Fragen nur als Verweis |
| `fragen.md` | Analyst, Auditor, Writer; `/work` markiert entschiedene Fragen und trägt meine Antwort wörtlich ein | die Fragen an mich, offen und entschieden: Kurzfassung, Details, `Antwort:`; nichts davon wird gelöscht |
| `plan.md` | Planner, `/work` (Nacharbeit) | Schritte, DoD-Mapping, Diagnose bei Bugs |
| `handover.md` | Writer | die Abnahmefläche: In 30 Sekunden, Diff mit Warum, DoD-Matrix, Checks, Reviewer, Prüfverlauf, Offen, Commits, PR-Titel (für den PR, den ich am Gate PR ohne Beschreibung anlege), Diff seit letzter Abnahme |
| `review.md` | `/review`, `/pre-review` | fremde Reviews (drei Reviewer, Über-Review, pro Befund n/3 und Urteil), von `/work` nicht angefasst |
| `pruefung/` | `/work` über `wl-write` | der Prüfverlauf: `verlauf.md` mit einer Zeile pro Agent-Aufruf (Phase, Runde, Agent, Ergebnis, Befund-Ids, Ausgang), `befunde.md` als Register (Id, Kriterium, Quelle, Befund, Status, Entscheidung) und je Aufruf eine Datei `NN-<phase>-<agent>-rN.md`, die `wl-write runde` selbst aus dem Agent-Transkript füllt (Brief und Abschlussbericht wörtlich, nichts wird vom Orchestrator abgetippt). `wl RTM-xxxx --runden` zeigt die Tabelle mit API-Aufrufen, Cache-Tokens und Dauer aus den Transkripten, `--sum` eine Zeile pro Phase, `wl-write befund RTM-xxxx list alle` das Register. Zeitstempel und Nummern schreibt ausschließlich `wl-write` mit der Systemuhr; ein Phasenwechsel ist ein Aufruf (`wl-write phase`). |

`wl` liest die `state.md`-Dateien: `wl` (Tabelle), `wl --open` (nur
wartende), `wl RTM-xxxx` (Gate, nächste Schritte, letzte Log-Zeilen).

## Worktree und Sessions

- **Agent-Sessions werden für Wiederholungsrunden fortgesetzt.** Ein
  Verifier, Reviewer, Analyst oder Planner, der den Code einmal gelesen
  hat, bekommt seine Runde 2 (nach fail, Zurückweisung, Auditor-Urteil oder
  Nacharbeit) als Nachricht an seine Agent-Id: 3 bis 5 Aufrufe statt 10 bis
  15, und der Cache ist noch warm. Frisch gestartet wird bei jeder neuen
  Phase, wenn die Worker-Session gewechselt hat, wenn die letzte Zeile des
  Agents im Prüfverlauf älter als 60 Minuten ist, oder wenn der erste Brief
  inhaltlich falsch war. Die Ids stehen in `state.md` (`verifier_id`,
  `reviewer_ids`, …); `wl RTM-xxxx --runden` rechnet einem fortgesetzten
  Agent nur die Aufrufe seit seiner vorigen Zeile zu.

- `wt add <repo> <branch>` legt Branch, Worktree, herdr-Space und Bootstrap
  an (eigener Compose-Stack, eigene Test-DB). Am Ende schreibt der Bootstrap
  `.wt-ready` in den Worktree, bei Fehler `.wt-failed`. Das ist eine
  Bereitschaftsmarke, kein Lock: `wt agent` wartet darauf, `/work` prüft sie
  vor dem ersten Implementer-Schritt. Ältere Worktrees ohne Marke gelten als
  bereit, wenn `vendor/` und `.env` da sind.
- `wt agent <repo>/<branch-dir> [--resume|--fresh] -- <Prompt>` ist die
  Automatisierung, die `/lead` nutzt: startet Claude im Root-Pane des
  Spaces (nach dem Bootstrap, dessen Ausgabe darüber stehen bleibt; kein
  Split), wenn keiner läuft, oder spricht die laufende Session an.
  Verweigert, wenn der Worker arbeitet oder in einem Prompt hängt.
- Ich kann alles auch von Hand machen: `wt`, in den Space, `claude`, dann
  `/work RTM-xxxx`. Eine von Hand gestartete Claude-Session im Space ist
  für herdr der Worker, `wt agent` findet sie und spricht sie an. `/work`
  liest immer `state.md`, deshalb ist egal, wer die Session gestartet hat.
- Eine Session pro Ticket: `/work` trägt seine Session-Id in `state.md`
  ein und stoppt, wenn eine andere Session dort steht und die Datei in den
  letzten zehn Minuten geschrieben wurde.
- Neu oder fortsetzen: `claude --continue` im Worktree setzt die letzte
  Session dieses Tickets fort. Fortsetzen bei Gate-Antwort oder Nacharbeit
  am selben Tag, frisch bei Phasenwechsel oder nach einem Tag Pause.
  `--fresh` auf eine laufende Session schickt `/clear`.
- Live-Test im Haupt-Checkout: `/worktree-move` (`wt main`) zieht den Branch
  in den Haupt-Checkout, `wt back` zurück.

## Tagesablauf

```
morgens   wt lead            → Space „lead" (cwd work-log), frische Session, /lead:
                               liest die letzte Tagesnotiz, wl, legt die heutige Notiz an,
                               /day morgen, Ticketliste, Worker starten (wt agent)
tagsüber  im Ticket-Space     → der Worker zeigt sein Gate, ich antworte dort
                               (/work RTM-x <…>), frage nach, diskutiere, lese
                               fragen.md; Permission-Prompts ebenfalls dort
          im Lead-Space       → eine Zeile pro Ereignis (Gate offen, beantwortet,
                               done) mit dem Space, in dem die Antwort erwartet wird;
                               /lead status für die Übersicht
abends    /lead abend         → /day abend: Slack-Status, Tagesnotiz mit Übertrag
morgen    wt lead             → neue Session, liest den Übertrag; die alte bleibt im Space
```

Der Lead ist absichtlich eine neue Session pro Tag: sein Kontext wächst mit
jeder Statuszeile, und alles, was er wissen muss, steht in der Tagesnotiz
und den `state.md`-Dateien. `wt lead` am selben Tag setzt die laufende
Session fort (`claude --continue`), an einem neuen Tag startet es frisch.
Der Space `lead` hat als Arbeitsverzeichnis den work-log-Store, weil dort
seine Dateien liegen und keine Projektregeln geladen werden.

Was der Lead bei „done" nachprüft, bevor er es mir meldet: Commits im
`git log` des Worktrees, gepushter Branch über `git ls-remote`, PR aus
`state.md` in Gitea (offen, nicht gemergt). Ein Worker-Bericht ist eine Behauptung.

## Stolpersteine

- **Worker starten in `acceptEdits` statt `auto`:** Claude Code liest die
  `.claude/settings.local.json` eines Worktrees aus dem Haupt-Checkout, und
  Projekt-Settings schlagen die User-Settings. Steht dort
  `"defaultMode": "acceptEdits"`, gilt das für jeden Worktree. Die Zeile aus
  `~/code/RED-telematik-manager/RED-telematik-manager/.claude/settings.local.json`
  entfernen; `auto` kommt dann aus `~/.claude/settings.json`. herdr ist
  unschuldig, `herdr agent start` ruft `claude` ohne Flags auf.

Weitere Umgebungs-Eigenheiten, die eine Runde gekostet haben (VPN,
Jira-Ausfall, Test-DB, Fixtures), gehören in die work-brain-Notiz
`pipeline-stolpersteine`.
Der Lead liest sie beim Start, der Analyst vor der Spec. Angelegt wird sie
über `/brain`, sobald der erste echte Eintrag da ist.

## Offene Punkte

- Rückmeldung zur Abnahme: im Chat (`nacharbeiten <Notiz>`) oder als
  Zeilenkommentare im PR (`nacharbeiten siehe PR`, der Worker liest sie
  nur). Beides geht; welcher Weg der normale wird, entscheide ich nach den
  ersten Tickets.
- **Umfang der Pipeline bei kleinen Tickets.** RTM-3899 (Bugfix, drei
  Zeilen) hat rund 9 Mio. Cache-Tokens gekostet; Spec-Prüfung, Planner,
  Plan-Prüfung und zweiter Reviewer haben dabei nichts verändert. Vorschlag
  einer S-Kurzstrecke (Analyst, Implementer, eine Branch-Prüfung, Writer)
  liegt vor; ob alle Schritte generell nötig sind, ist noch zu diskutieren.
  Für große Tickets: Spec und Plan einmal, Etappen mit Teil-Abnahme, nicht
  jeden Chunk durch die ganze Pipeline.
- Ob der Lead kleine Operationen (Jira-Transition) nach Go selbst
  ausführen darf; Push und Merge bleiben in jedem Fall bei mir. Erst nachjustieren, wenn der Umweg über den Worker klemmt.
- Der Nachrichtenweg Lead ↔ Worker ist noch nicht im echten Lauf getestet:
  ob eine Nachricht an eine wartende Session dort wie eine Eingabe wirkt, und
  was passiert, wenn der Worker gerade in einem Permission-Prompt hängt.
