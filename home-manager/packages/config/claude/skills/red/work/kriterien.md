# Regeln der Pipeline

Was in jeder Phase gilt, damit die nächste beginnt. Die Listen gelten für
jedes Ticket gleich und werden hier gepflegt, nicht pro Ticket erfunden.
Keine Größenklassen: Tickets sind klein genug, dass ein Fluss für alle
reicht. Was nicht klein genug ist, fällt in der Analyse als `Umbau` auf
und wird mit Tobias besprochen.

## Scope- und Lücke-Regel (alle Rollen)

Ein DoD-Item ist eine Aussage des Tickets (Akzeptanzkriterium, SOLL,
Hinweis Dev), nie eine Idee eines Agenten. Alles, was über den Wortlaut des
Tickets hinausgeht (ein Feld, das das Frontend bräuchte; ein
Geschwister-Ablauf mit demselben Fehler; ein Refactoring, das die Regeln
nahelegen; eine Änderung an geteiltem Code, den andere Abläufe nutzen), ist
eine Frage an Tobias oder steht unter Scope `out:`, nie im DoD. Stellt ein
Agent fest, dass das Ticket sich widerspricht oder etwas Falsches
voraussetzt, ist die Folgefrage immer `Lücke`, egal wie technisch die
Optionen aussehen. „Für Nutzer nicht sichtbar" ist kein Argument gegen
Scope: RTM-3919 (Fehlerstatus in der geteilten Aktion, von Tobias
zurückgedreht) und RTM-3883 (neues API-Feld ohne Gate) sind die Belege.

## A · Analyse (der Orchestrator selbst)

| Nr | Regel |
|---|---|
| A1 | Der Hergang steht als Kette von außen nach innen in `ticket.md`: Auslöser, Klassen in Aufrufreihenfolge mit `file:line`, Ansatzstelle. Lässt sich das Ticket nicht als Kette rekonstruieren, ist das eine `Lücke` |
| A2 | Jede Behauptung des Tickets (Ursache, „ist bereits gesperrt", „nutzt X") ist am Code verifiziert; eine widerlegte Behauptung ist eine `Lücke`-Frage, nie eine stille Korrektur |
| A3 | Jede SOLL-Aussage hat ein prüfbares Kriterium im DoD; eine SOLL-Aussage ohne prüfbares Kriterium ist eine Frage |
| A4 | Geschwister-Stellen (gleiche Schleife, gleicher Guard, gleicher Aufrufer) sind gesucht und stehen unter `in:` oder `out:` mit Grund; eine Teilmenge nur mit Grund und als Frage |
| A5 | Annahmen über echte Daten (gibt es die Fälle, wie viele, welche Form) stehen als Aufgabe für Tobias mit fertigem Statement, `vor dem Bauen` |
| A6 | Jede nötige Änderung an geteiltem Code, an einem API-Vertrag oder an Daten ist eine Frage oder ein `Umbau`-Hinweis, keine Entscheidung |
| A7 | Verhalten, das weder Ticket noch Code festlegen und das Nutzer sehen, ist eine `Produkt`-Frage |
| A8 | Breite: so viel lesen, wie der Hergang braucht (das Subsystem, seine Aufrufer, seine Tests), kein Sweep über das Repo; dann schreiben. Was danach zählt, steht in `ticket.md`, nicht im Kopf; eine frische Session liest die Datei, nicht den Verlauf |
| A9 | Ein Bug wird vor dem Bauen nachgestellt: die Kette bis zur Zeile, der konkrete Auslöser, die falsche Wirkung, der Test, der rot werden müsste. Ruht das Ticket auf einem Vorfall (Logzeile, Kibana-Fehler, „tritt auf"), liefert Tobias den Beleg: fertige Kibana-Abfrage oder Prod-SQL unter „Für Tobias · vor dem Bauen", dazu die Frage (`Daten`): A trotzdem bauen, weil die Lücke im Code steht · B zurück an den Ersteller mit den Belegen · C ins Team. Ein Bug, dessen Kette sich am Code nicht nachstellen lässt, ist eine `Lücke`, kein Bau |

## L · Der Loop (Implementer → Refactorer → Logik-Review)

| Nr | Regel |
|---|---|
| L1 | Der Implementer baut jedes DoD-Item mit einem Test, der ohne die Änderung rot wäre, und nichts außerhalb des Scope; eine fachliche Frage aus dem Bau heraus hält den Loop (`frage`). Eine Migration, die Daten löscht oder umschreibt, hat immer einen Test (notfalls über eine temporäre Tabelle, Vorbild RTM-3836) oder ist eine Frage an Tobias; „manuell gegen die Test-DB geprüft" ist kein Nachweis und keine zulässige Abweichung |
| L2 | Der Refactorer ändert Struktur, Namen, Schicht und Konventionen nach den Regeln der berührten Pfade und lässt danach dieselben Tests laufen; das Verhalten bleibt, die DoD-Tests bleiben grün |
| L3 | Bestandscode ändert der Refactorer nur als mechanische Folge (Aufrufer nach Umbenennung) oder wenn eine Regel es direkt verlangt und die Änderung bei den berührten Klassen bleibt; alles darüber ist `eskalation` mit Vorschlag und Reichweite, der Loop wartet |
| L4 | Der Logik-Review ist lesend: jedes DoD-Item hat einen Test mit Nachweis (ein DoD-Item „nur manuell geprüft" ist `major`, auch wenn der Implementer es als Abweichung gemeldet hat), die im Brief benannten Testdateien der berührten Klassen und ihrer Aufrufer sind grün (selbst gelaufen, keine Verzeichnisse, keine Suite), Fehlerszenarien sind als Kette von außen nach innen belegt |
| L5 | Der Loop endet, wenn der Logik-Review keinen Befund der Schwere `major` oder `blocker` offen hat; `minor` geht als Hinweis mit. Befunde gehen an den Implementer (fortgesetzt), dann Refactorer (fortgesetzt, nur das Delta), dann Logik-Review (fortgesetzt). Nach drei Durchläufen `ESK` |
| L6 | Die Commits folgen C1–C5; die Zurückweisung eines Befunds (`zurückgewiesen: <Beleg>`) entscheidet der Orchestrator am Code, nicht ein weiterer Agent |

## C · Commits (Tobias' Vorgabe vom 2026-10-07)

| Nr | Regel |
|---|---|
| C1 | Commits sind nach gemachter Änderung geschnitten, nicht nach Loop-Runde: zuerst der Domain- und Datenanteil (Modelle, Enums, Migrationen, je mit ihren Tests), dann logisch gruppierte Änderungen im Service-Layer (Aktionen, Abfragen, Jobs, je mit Tests), dann die HTTP-Schicht, dann der Rest. Der Refactorer liefert den Schnitt (`COMMITS:`), der Orchestrator führt ihn aus |
| C2 | Bestandscode, der nicht direkt zum Feature gehört, ist ein eigener `chore`-Commit; ein regelgetriebenes Umstrukturieren von Bestandscode ist ein eigener `refactor`-Commit. Beides nie im Feature-Commit |
| C3 | Jede spätere Änderung (Loop-Runde ≥ 2, Fix aus dem Voll-Review, CI-Fix am neuen Code, Nacharbeit nach ABNAHME) wird in den Commit gefaltet, zu dem sie gehört (`git commit --fixup`, `git rebase --autosquash <base>`); eine neue logische Gruppe wird ein neuer Commit. Kleinigkeiten sind nie ein eigener Commit |
| C4 | Das gilt bis zum Merge nach `develop`, auch nach dem Push; den Force-Push macht Tobias am PR-Gate |
| C5 | Abgewichen wird nur, wenn der Fixup kompliziert oder riskant wird (Konflikt im Rebase): dann bleibt die Änderung ein eigener `fix`-Commit, und die `handover.md` sagt warum |

Nachricht immer `<type>(<scope>): <description> <TICKET>`, eine Zeile, kein
Body, kein Trailer (`.claude/rules/commit-messages.md`).

## V · Voll-Review (zwei unabhängige Reviewer, der Orchestrator führt zusammen)

| Nr | Regel |
|---|---|
| V1 | Zwei Reviewer, blind zueinander, identischer Brief, jeder der ganze Stand gegen Regeln und Logik; keine Aufteilung nach Dateien oder Themen |
| V2 | Der Orchestrator führt zusammen (gleiche Stelle und gleiche Behauptung → ein Befund, Zähler n/2 als Information) und widerlegt selbst am Code; er lässt nie einen Befund fallen, weil nur einer ihn sah |
| V3 | Befangenheit: einen `scope`-Befund weist er nur mit einer Ticket-Stelle zurück, nie mit seiner eigenen `ticket.md`; ein Konflikt zwischen beiden Reviewern und seiner Widerlegung geht als offene Frage in die `handover.md` |
| V4 | `minor` ohne Verhaltensänderung (Name, Import, Assertion, Reihenfolge) fixt er selbst, lässt PHPStan, Pint und die berührten Tests laufen und faltet die Änderung in den zugehörigen Commit (C3); `major` und `blocker` gehen als Befunde in den Loop (ein weiterer Durchlauf, zählt nicht gegen L5) |
| V5 | Danach Voll-Review erneut mit denselben Reviewern über den ganzen Stand; Ende, wenn kein `major`/`blocker` offen ist; nicht gefixte `minor` stehen als Hinweise in der `handover.md`. Nach zwei Runden `ESK` |

## Schwere

| Schwere | Bedeutung |
|---|---|
| `blocker` | falsche oder verlorene Daten, Autorisierungslücke, eine Struktur, die nach dem Merge wieder aufgerissen werden müsste (falsche Schicht besitzt Zustand, Vertrag, auf den anderer Code bauen wird) |
| `major` | ein heute erreichbares falsches Verhalten, ein DoD-Item ohne Nachweis, eine Regelverletzung mit Folge, jede Änderung über den Ticket-Scope hinaus (`scope`) |
| `minor` | eine Regelverletzung ohne Folge, ein schwacher Test, der das Verhalten trotzdem beweist |

Nichts darunter. Eine Vorliebe ohne Regel oder Vorbild (`file:line`) ist kein
Befund.

## Schreibregeln für alles, was Tobias liest

(`ticket.md`, Gate, Eskalation, `handover.md`, Antworten auf Rückfragen)

- **Hergang zuerst, von außen nach innen:** wer oder was stößt den Fall an
  (UI, Endpoint, Scheduler, Job, Event), welche Klassen folgen in welcher
  Reihenfolge, an welcher Stelle liegt das Problem oder die Änderung. Erst
  dann Optionen und Schwere. Eine Liste von `file:line` ohne Kette lässt ihn
  die Schwere nicht einschätzen.
- Keine unerklärten Kürzel, Fehlercodes oder Klassennamen, immer Klartext
  daneben („Fremdschlüssel-Fehler der Datenbank (MySQL 1452)").
- Umfang nennen: was betroffen ist und was nicht.
- Leerzeilen zwischen Blöcken, Listen statt Fließtext, kurze Sätze.
- Evidenz und Vermutung immer getrennt; eine Vermutung heißt `Vermutet:`
  und nennt, wie sie zu prüfen wäre.
- Jede Empfehlung nennt ihr eigenes Risiko.
- Eingriffe mit Verlustpotenzial (Locks, die Jobs verwerfen; Löschungen;
  Migrationen, die Daten entfernen) brauchen echte Evidenz, sonst steht
  „nicht belegt" als Risiko da und die Option ohne Verlust ist der Default.
- Optionen sind in Datei und Gate identisch: gleiche Menge, gleiche
  Buchstaben, gleiche Namen. Option A ist das Ticket wörtlich.
- Eine Frage setzt keine Agenten-Entscheidung als gegeben voraus („in
  beiden Optionen gilt …"); dann steckt die eigentliche Frage dort.
