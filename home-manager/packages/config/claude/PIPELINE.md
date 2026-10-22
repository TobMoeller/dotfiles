# Die Ticket-Pipeline

Das ist die Beschreibung des Flows für Menschen. Die ausführbaren Fassungen
sind die Skills `/lead`, `/work`, `/day` und die Agent-Profile unter
`~/.claude/agents/`. Wenn sich etwas widerspricht, gilt der Skill, und diese
Datei wird nachgezogen.

## In einem Satz

Ich (Tobias) spreche mit `/lead` darüber, welche Tickets heute laufen. Jedes
Ticket bekommt einen Worktree und eine eigene Claude-Session. Darin
analysiert `/work` das Ticket selbst, lässt es von einem Loop aus drei
Agents bauen (Implementer, Refactorer, Logik-Review), lässt den fertigen
Stand von zwei unabhängigen Reviewern prüfen, bewertet deren Befunde
selbst, schreibt die Übergabe und wartet regulär nur einmal auf mich:
bevor irgendetwas das Gerät verlässt. Vor dem Bauen hält sie nur, wenn das
Ticket eine Lücke hat oder ein größerer Umbau absehbar ist; das bespreche
ich dann mit der Session, die das Ticket kennt.

Seit 2026-10-07 ist das der einzige Fluss. Keine Größenklassen, keine
Spec-Phase, kein Plan, keine Schritt-Prüfung. Anlass und Messgrößen
stehen unter Offene Punkte.

## Die drei Ebenen

| Ebene | Wo | Was sie tut | Was sie nie tut |
|---|---|---|---|
| `/lead` | eine Session pro Tag, herdr-Space `lead`, cwd `work-log` (`wt lead`) | Tagesplan, Worker starten, Gate-Nachrichten empfangen, „done" nachprüfen, Tagesnotiz führen | Code, Reviews, Jira-Schreibzugriff, Permission-Prompts beantworten |
| `/work` (Worker) | eine Session pro Ticket, im Worktree | analysiert das Ticket (`ticket.md`), stellt Bugs nach, brieft die Agents, bewertet ihre Ergebnisse, führt Review-Befunde zusammen und widerlegt sie, fixt Kleinigkeiten, schneidet und faltet Commits, schreibt `handover.md`, entwirft Folgetickets, ist mein Gesprächspartner | Feature-Code und Tests schreiben, pushen, PR anlegen, mergen |
| Agents | Subagents des Workers, jeder behält seine Session über die Runden | je eine Station mit festem Ergebnisblock | Zustand halten, miteinander reden, committen |

Lead und Worker sind getrennte Claude-Sessions und sprechen über
`SendMessage` miteinander (`ListAgents` zeigt die Namen). Der Lead schreibt
seinen Namen beim Start nach `work-log/.lead-session`; ein Worker schickt
dorthin jeden Gate-Block und die Done-Zeile. Der Lead antwortet mit
`/work RTM-xxxx <Antwort>` als Nachricht an den `session_name` aus der
`state.md`. herdr bleibt die Sicht von außen (idle, working, blocked) und
der Ort, an dem ich Permission-Prompts beantworte.

Lead, Worker und Agents laufen auf Opus 5.5 (Lead seit 2026-10-22 testweise
statt Fable: seine Arbeit ist `wl`, Jira-Suchen und Nachrichten, Fable
brachte dort keinen Mehrwert; zurück mit `WT_LEAD_MODEL=fable`). Einzige
Ausnahme: der zweite Voll-Reviewer (B) läuft seit 2026-10-22 auf Fable 5.1,
als Versuch, ob ein zweites Modell eine zweite Perspektive bringt. Gemessen
wird über die Quelle-Spalte im Befund-Register (`Voll r1 A`, `B`, `A+B`):
Befunde, die nur B sah, gegen die, die nur A sah, nach Schwere und Ausgang.

| Agent | Station | Darf | Gibt zurück |
|---|---|---|---|
| `implementer` | Loop 1 | baut das ganze Ticket aus `ticket.md`: Funktionalität und je DoD-Item ein Test, der ohne die Änderung rot wäre; liest von den Regeln nur die Testkonventionen; in Runde ≥ 2 setzt er die Befunde des Logik-Reviews pro Id um oder weist sie mit Beleg zurück | Dateien, Checks, technische Entscheidungen, Abweichung, ggf. eine fachliche Frage |
| `refactorer` | Loop 2 | liest alle Regeln der berührten Pfade als Hauptaufgabe und ändert den Code direkt: Schicht, Muster, Benennung, Fehlerbehandlungs-Eigentum, Testkonventionen; lässt dieselben Tests laufen; Bestandscode nur als mechanische Folge oder auf direkte Regel, sonst Eskalation mit Vorschlag und Reichweite | Umbauten mit Regelbeleg, Bestands-Änderungen, Commit-Zeile, ggf. Eskalation |
| `reviewer` Modus logik | Loop 3, lesend | prüft, ob jedes DoD-Item einen Test mit Nachweis hat, führt die Tests der berührten Klassen und Aufrufer aus, sucht Fehlerszenarien als Kette von außen nach innen, prüft Diff gegen SOLL | Befunde mit Schwere, DoD-Nachweise |
| `reviewer` Modus voll ×2 | Voll-Review, lesend | jeder der ganze Stand gegen Regeln, Logik, Struktur und Scope; blind zueinander, nichts aufgeteilt | Befunde mit Schwere |

## Die Phasen

```
assess ──FRAGEN?──▶ build ──────────────────────────▶ review ──────────────────▶ accept ──PR──▶ ──ABNAHME──▶ done
Worker:            Implementer → Refactorer →        Reviewer ×2 (voll)        Worker: handover.md
ticket.md          Reviewer (logik)                  Worker: zusammenführen,
(Hergang, DoD,     ↺ bis kein major/blocker,         widerlegen, Kleinigkeiten
Scope, Fragen)     ein Commit pro Runde,             fixen, Größeres → Loop
                   max 3 Runden, dann ESK            ↺ max 2 Runden, dann ESK
```

1. **assess.** Der Worker liest Ticket und Subsystem selbst und schreibt
   `ticket.md`: das Ticket in einem Satz, den **Hergang** als Kette von
   außen nach innen (Auslöser, Klassen in Reihenfolge mit `file:line`, die
   Stelle, an der das Ticket ansetzt), die DoD wörtlich aus dem Ticket,
   Scope in/out, Einstieg und Hinweise für die Agents, Fragen an mich,
   Aufgaben für mich, Entscheidungen. Die Prüfliste dafür (A1 bis A8 in
   `kriterien.md`): jede Behauptung des Tickets am Code verifiziert, jede
   SOLL-Aussage mit prüfbarem Kriterium, Geschwister-Stellen gesucht,
   Datenannahmen benannt, jede Änderung an geteiltem Code als Frage,
   sichtbares undefiniertes Verhalten als Frage. Ein Ticket, das sich nicht
   als Kette rekonstruieren lässt, hat eine Lücke. Alles über den Wortlaut
   des Tickets hinaus ist Frage oder `out:`, nie DoD. Breite: was der
   Hergang braucht, kein Sweep über das Repo. **Bugs werden vor dem Bauen
   nachgestellt** (A9): die Kette bis zur Zeile, der konkrete Auslöser, der
   Test, der rot werden müsste. Ruht das Ticket auf einem Vorfall (Logzeile,
   Kibana), liefere ich den Beleg: der Worker legt mir die fertige
   Kibana-Abfrage oder das Prod-SQL unter „Für Tobias · vor dem Bauen" hin,
   dazu die Frage, ob wir trotzdem bauen, das Ticket mit den Belegen an den
   Ersteller zurückgeben oder ins Team tragen. RTM-3836 hat gezeigt, warum:
   zwei Monate Log ohne den zitierten Fehler, erst nach der Abnahme
   bemerkt.
2. **FRAGEN.** Gibt es eine Frage, einen Umbau-Hinweis oder eine Aufgabe
   „vor dem Bauen", hält die Pipeline und ich entscheide im Gate, mit dem
   Worker, der den Hergang kennt; Rückfragen beantwortet er selbst aus
   seiner Analyse. Kein Prüfagent dazwischen. Sonst kein Halt.
3. **build.** Der Loop. Implementer baut Funktionalität und Tests, roh.
   Refactorer bringt das in Form, mit allen Regeln im Kontext, ändert
   direkt, lässt die Tests laufen; was an Bestandscode größer wäre,
   eskaliert er statt es zu tun. Der Worker committet die Runde.
   Logik-Review prüft Nachweise, Tests und Fehlerszenarien, lesend. Bleibt
   kein Befund der Schwere major oder blocker, ist der Loop fertig; sonst
   gehen die Befunde pro Id an den Implementer, dann Refactorer über das
   Delta, dann derselbe Reviewer, alle in ihren Sessions. Höchstens drei
   Runden, dann ESK. Zurückweisungen eines Befunds entscheidet der Worker
   am Code. Eine fachliche Frage aus dem Bau heraus hält am FRAGEN-Gate,
   der Stand bleibt stehen.
4. **review.** Zwei Reviewer parallel, blind, identischer Brief, jeder der
   ganze Stand. Der Worker führt zusammen (gleiche Stelle, gleiche
   Behauptung → ein Befund, Zähler als Information, nichts fällt weg, weil
   nur einer es sah), widerlegt am Code mit seinem Ticket-Wissen, setzt
   die Schwere. Kleinigkeiten ohne Verhaltensänderung fixt er selbst,
   Checks, Commit. major und blocker gehen als eine Loop-Runde zurück,
   danach Voll-Review erneut mit denselben Reviewern. Ende, wenn nichts
   major/blocker offen ist; nicht gefixte minor stehen als Hinweise in der
   Übergabe. Zwei Runden, dann ESK. Befangenheit: einen Scope-Befund weist
   er nur mit einer Ticket-Stelle zurück, nie mit seiner eigenen
   `ticket.md`; einen Konflikt zwischen beiden Reviewern und seiner
   Widerlegung sehe ich in der Übergabe mit beiden Positionen.
5. **accept.** Der Worker schreibt `handover.md`: In 30 Sekunden, Hergang
   der Änderung von außen nach innen, Diff mit Warum, DoD-Matrix, Checks,
   Entscheidungen unterwegs (seine, die des Implementers, die Umbauten des
   Refactorers), Hinweise der Reviewer, Offen, Für dich zu tun,
   Prüfverlauf, Commits, PR-Titel. Dann Gate PR: ich pushe und lege den PR
   ohne Beschreibung an, der Worker prüft lesend. Dann ABNAHME.

**Nacharbeit** ist immer dasselbe: meine Notiz wird ein Befund mit Id,
eine Loop-Runde (Implementer, Refactorer, Logik), Voll-Review mit
denselben Reviewern, Übergabe mit „Diff seit letzter Abnahme", Push, neue
Abnahme. Meine Notiz zählt nicht gegen das Rundenlimit.

## Die Gates

Ein Gate ist ein Block `## Gate` in der `state.md` des Tickets plus ein
beendeter Turn. Kein Dialog. **Beantwortet wird im Ticket-Tab:** der Worker
druckt den Block in seinem Space, dort antworte ich mit `/work RTM-xxxx
<Antwort>`, frage nach, diskutiere, oder schreibe die Antwort in `ticket.md`
und sage `siehe ticket.md`. Der Lead bekommt nur eine Zeile (Gate offen,
Gate beantwortet, done) für die Tagesnotiz und sagt mir, in welchem Space
die Antwort erwartet wird. `wl RTM-xxxx` zeigt den offenen Block, `wl
--open` alle.

**Welche Fragen mich erreichen.** Jede Frage trägt eine Klasse und geht
direkt an mich, nach der Formprüfung des Workers selbst (Hergang zuerst,
Optionen in Datei und Gate identisch, Belege, Vermutungen markiert, keine
vorausgesetzte Agenten-Entscheidung). Kein Agent entscheidet, was ich sehe.

| Klasse | Bedeutung |
|---|---|
| `Lücke` | das Ticket lässt etwas offen, widerspricht sich oder setzt etwas voraus, das der Code widerlegt |
| `Aufwand` | eine Vorgabe kostet weit mehr als das Ticket vermuten lässt, oder eine einfachere Lösung erfüllt den Zweck |
| `Nutzer` | eine Vorgabe ist für Nutzer oder Betrieb ungünstig |
| `Daten` | die Lösung ruht auf einer Annahme über echte Daten; das Statement liegt bei, Antwort vor dem Bauen |
| `Produkt` | Verhalten, das weder Ticket noch Code festlegen und das Nutzer sehen |
| `Umbau` | die saubere Lösung braucht mehr als das Ticket vermuten lässt: geteilte Klasse, mehrere Aufrufer, Migration; aus der Analyse oder vom Refactorer |

Was mich nicht erreicht: unmarkierte Vermutungen, technische Wahlen ohne
Reichweite über das Ticket hinaus (die trifft der Implementer, der
Refactorer und das Review prüfen sie). Was mich immer erreicht: ein
Widerspruch im Ticket und jede Option, die Verhalten für Abläufe außerhalb
des Tickets ändert, egal wie technisch sie aussieht (gelernt an RTM-3919
und RTM-3883).

| Gate | Art | Wann | Was ich entscheide | Antwort |
|---|---|---|---|---|
| **FRAGEN** | hart, nur wenn es Fragen, einen Umbau oder eine Aufgabe „vor dem Bauen" gibt | nach assess; aus dem Loop heraus bei einer fachlichen Frage des Implementers | die Fragen an mich, in einem Rutsch | `ok` (alles wie empfohlen) · `1: <Option oder eigener Text> 2: <…>` (abweichend, Rückfrage oder Kontext; Rest wie empfohlen) · `siehe ticket.md` · `diskussion <n>` · `nein: <Notiz>` · jeweils `manual` anhängen = ich committe selbst |
| **ESK** | hart | der Refactorer eskaliert ein Bestands-Refactoring, ein Rundenlimit ist erschöpft, ein Widerspruch zum Ticket beim Bauen | die eine Frage oder „Wie weiter?" | `1: A` · `1: <eigener Text>` · `redo <phase>` · `park <Notiz>` · `diskussion 1` |
| **PR** | hart, kurz, nicht Teil der Abnahme | nach review, `handover.md` liegt vor; nach jeder Nacharbeit erneut (dann nur Push) | nichts, ich pushe und lege den PR an | `pr da` (Worker prüft Branch und PR lesend, trägt `pr:` ein, postet beim ersten Mal den nackten PR-Link als Jira-Kommentar ohne Prompt, dann ABNAHME) · `ohne pr` · `parken` |
| **ABNAHME** | hart, immer | nach PR | abnehmen oder zurückschicken | `abnehmen` (kein Jira-Schreibzugriff mehr, der Link steht seit `pr da` im Ticket; der PR bleibt offen, mergen tue ich) · `abnehmen ohne-jira` · `nacharbeiten <Notiz>` (`siehe PR` = meine Kommentare im PR) · `parken` · offene Punkte wie bei FRAGEN |

**Befund-Register.** Jeder Befund eines Reviewers und jede Nacharbeit-Notiz
von mir bekommt eine Id in `pruefung/befunde.md` und wird fortan nur über
die Id angesprochen: der Implementer antwortet `umgesetzt` oder
`zurückgewiesen: <Beleg>`, Zurückweisungen entscheidet der Worker am Code,
das Re-Review bestätigt `erledigt` oder `offen`. Status: offen, umgesetzt,
zurückgewiesen, widerlegt, gefixt (Orchestrator), Hinweis. Entschiedene Ids
tauchen in keiner späteren Prüfung wieder auf, außer mit neuem Beleg als
neue Zeile.

**Schwere.** blocker: falsche oder verlorene Daten, Autorisierungslücke,
eine Struktur, die nach dem Merge wieder aufgerissen werden müsste. major:
heute erreichbares falsches Verhalten, DoD-Item ohne Nachweis,
Regelverletzung mit Folge, jede Änderung über den Ticket-Scope hinaus.
minor: Regelverletzung ohne Folge, schwacher Test, der trotzdem beweist.
Nichts darunter; eine Vorliebe ohne Regel oder Vorbild ist kein Befund.

Rundenlimits: Loop 3 Runden · Voll-Review 2 Runden · jeweils dann ESK ·
meine Nacharbeit-Notiz startet die Zählung neu · Rückfragen von mir ohne
Limit (ab der zweiten zur selben Frage geht die Diskussion in den
Worker). Erwartete Form für ein normales Ticket: Analyse im Worker,
Implementer, Refactorer, Logik-Review, null bis eine weitere Loop-Runde
mit denselben drei Agents, zwei Voll-Reviewer, null bis ein Re-Review, also
6 bis 10 Agent-Aufrufe.

**Commits.** `commits: auto` ist der Default aus der Vorlage und meine
stehende Entscheidung: der Worker committet. Abwählen pro Ticket mit
`/work RTM-xxxx commits manual`, mit `manual` in einer Gate-Antwort oder im
Start-Prompt über den Lead („ich committe selbst"). Zurück nur mit
`commits auto` von mir.

Die Commits sind nach gemachter Änderung geschnitten, nicht nach Runde
(C1 bis C5 in `kriterien.md`): zuerst Domain- und Datenanteil, dann
logisch gruppiert der Service-Layer, dann HTTP, dann der Rest; Bestandscode
ohne direkten Feature-Bezug als eigener `chore`, regelgetriebene Umbauten
als eigener `refactor`. Den Schnitt liefert der Refactorer, der Worker
führt ihn aus. Jede spätere Änderung (weitere Loop-Runde, Fix aus dem
Voll-Review, CI-Fix am neuen Code, Nacharbeit nach der Abnahme) wird mit
`git commit --fixup` und `git rebase --autosquash` in den Commit gefaltet,
zu dem sie gehört, bis zum Merge nach `develop`, auch nach dem Push; den
Force-Push mache ich am PR-Gate (`--force-with-lease`). Abgewichen wird
nur, wenn der Fixup im Rebase kollidiert: dann bleibt ein eigener
`fix`-Commit, und die Übergabe sagt warum.

### So sieht ein Gate aus

Im Chat druckt der Worker das Gate als normales Markdown (fette Kopfzeile
mit Gate, Ticket und Uhrzeit, TLDR als Absatz, Fragen mit fettem Titel,
Antworten als Liste mit je einem Befehl pro Zeile), nie in einem
Code-Block: Claude Code zeigt Code-Blöcke einfarbig und ohne Formatierung.
In `state.md` steht derselbe Inhalt in der Dateiform darunter.

Jeder Gate-Block ist in 30 Sekunden entscheidbar, in einfachem Deutsch,
Hergang zuerst, ohne Klassennamen und Codes oberhalb der Details, höchstens
25 Zeilen, Leerzeilen zwischen den Blöcken:

```
FRAGEN · <Datum Uhrzeit>

TLDR: <ein Satz: das Problem mit Umfang und was gebaut wird>

Frage 1 · <Titel>
- <Hergang: wer stößt den Fall an, welche Klassen folgen, wo sagt das Ticket X und der Code zeigt Y>
- <Optionen: A = das Ticket wörtlich → Folge · B → Folge>
- <Empfehlung mit Grund · Risiko>
→ ticket.md#frage-1

Für dich zu tun: <nur was nur ich kann, mit „vor dem Bauen" / „vor dem Deploy">

Antwort: <eine Zeile, jede Antwort mit ihrer Folge>
Details: <eine Zeile: Branch, Runde, Pfad zu ticket.md, Hinweise>
```

ESK, PR und ABNAHME nutzen dieselbe Form (ESK mit der einen Frage oder
„Wie weiter?" und Belegen darunter in `state.md`; PR ohne Fragen, nur
Push-Befehl und PR-Titel unter „Für dich zu tun"; ABNAHME aus
`handover.md`).

### Fragen, Antworten, Rückfragen

`ticket.md ## Fragen` hält die Fragen der Pipeline an mich, offene und
entschiedene, mit meinen Antworten. Pro Frage: Klasse, Hergang (zwei bis
vier Sätze von außen nach innen), Optionen (A ist das Ticket wörtlich),
Empfehlung mit eigenem Risiko, Belege, eine Zeile `Antwort:`. Eine Frage,
die ich gesehen habe, wird nie gelöscht oder gekürzt; bei der Entscheidung
bekommt die Überschrift `— entschieden: <Option> (<Datum>)`, und in der
Antwort-Zeile steht meine Antwort wörtlich mit Quelle. Ins Gate kommen nur
die offenen.

Antworten gehen beide Wege: im Chat (direkt oder über den Lead) oder im
Dokument in der Zeile `Antwort:`, dann `/work RTM-xxxx` bzw. `siehe
ticket.md`. Im Dokument heißt eine leere Antwort „noch offen", nicht „ok".

Eine **Rückfrage** öffnet keine neue Runde. Der Worker beantwortet sie
selbst, aus seiner Analyse, der `ticket.md`, dem Diff und einem gezielten
Blick in die zitierten Stellen; die Antwort steht nur im Chat, und meine
Rückfrage wird nie zu einer neuen Frage an mich. Nur wenn sich dadurch die
Frage selbst ändert, wird ihr Abschnitt neu geschrieben, die vorige Fassung
bleibt eingeklappt darunter. Ab der **zweiten Rückfrage** zur selben Frage,
oder wenn ich `diskussion <n>` sage, wandert die Frage in den Worker-Space:
der Lead hält sich raus, ich schreibe drauflos, der Worker läuft erst
weiter, wenn ich entschieden habe.

**Schreibregeln** für alles, was ich lese (`ticket.md`, Gate, Eskalation,
`handover.md`, Antworten auf Rückfragen): Hergang zuerst, von außen nach
innen (Auslöser, Klassen in Reihenfolge, Problemstelle), erst dann Optionen
und Schwere · keine unerklärten Kürzel, Fehlercodes oder Klassennamen,
immer Klartext daneben · Umfang nennen: was betroffen ist und was nicht ·
Leerzeilen zwischen Blöcken, Listen statt Fließtext, kurze Sätze · Evidenz
und Vermutung immer getrennt · jede Empfehlung nennt ihr eigenes Risiko ·
Eingriffe mit Verlustpotenzial brauchen echte Evidenz, sonst steht „nicht
belegt" als Risiko da.

## Was ohne mich passiert und was nicht

Ohne Prompt: lesen, Tests, Lint, Edits im Worktree (Agents im Loop, der
Worker nur für Kleinigkeiten aus dem Voll-Review), `git add`, `git commit`
nach jeder Loop-Runde und nach einem Kleinigkeits-Fix (wenn `commits:
auto`; die Message ist genau die Commit-Zeile, ohne Trailer), Subagents
starten, Nachrichten zwischen Lead und Worker, der eigene Compose-Stack,
Jira-Schreibzugriffe, die ich im Chat angefordert habe oder die der
Schritt vorsieht (der nackte PR-Link bei `pr da`): meine Anweisung ist die
Freigabe, ein zweiter Prompt bringt nichts.

Immer mit Prompt im Worker-Space (das ist der Zweck, nicht ein Fehler):
jeder Schreibzugriff auf Gitea und Confluence außerhalb der Pipeline,
`wt rm`/`wt main`/`wt back`, `docker compose down` mit Volumes,
Branch löschen, Dateien unter `.claude/` oder `.env` in einem Worktree.

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
| `state.md` | `/work` | Frontmatter (phase, gate, round, commits, session, Agent-Ids, pr, …), `## Nächster Schritt`, `## Gate`, `## Offene Fragen` (Index für `wl`), `## Commits`, `## Gates`, `## Log` |
| `ticket.md` | `/work` | die Analyse: Ticket in einem Satz, Hergang, DoD mit Nachweisen, Scope, Einstieg und Hinweise, Fragen mit meinen Antworten (nichts davon wird gelöscht), Für Tobias, Entscheidungen (Worker, Implementer, Refactorer, Review, Tobias) |
| `handover.md` | `/work` | die Abnahmefläche: In 30 Sekunden, Hergang der Änderung, Diff mit Warum, DoD-Matrix, Checks, Entscheidungen unterwegs, Hinweise der Reviewer, Offen, Für dich zu tun, Prüfverlauf, Commits, PR-Titel, Diff seit letzter Abnahme |
| `review.md` | `/review`, `/pre-review` | fremde Reviews (zwei bis drei Reviewer, vom Aufrufer zusammengeführt und widerlegt), von `/work` nicht angefasst |
| `pruefung/` | `/work` über `wl-write` | der Prüfverlauf: `verlauf.md` mit einer Zeile pro Agent-Aufruf (Phase, Runde, Agent, Ergebnis, Befund-Ids, Ausgang), `befunde.md` als Register (Id, Schwere, Quelle, Befund, Status, Entscheidung) und je Aufruf eine Datei `NN-<phase>-<agent>-rN.md` aus dem Agent-Transkript (Brief und Abschlussbericht wörtlich). `wl RTM-xxxx --runden` zeigt die Tabelle mit API-Aufrufen, Cache-Tokens und Dauer, `--sum` eine Zeile pro Phase, `wl-write befund RTM-xxxx list alle` das Register. Zeitstempel und Nummern schreibt ausschließlich `wl-write` mit der Systemuhr. |

Ein `spec.md` aus einem früheren `/spec` ist Kontext für die Analyse, kein
Ersatz für `ticket.md`.

`wl` liest die `state.md`-Dateien: `wl` (Tabelle), `wl --open` (nur
wartende), `wl RTM-xxxx` (Gate, nächste Schritte, letzte Log-Zeilen).

## Worktree und Sessions

- **Agent-Sessions werden über die Runden fortgesetzt.** Die drei
  Loop-Agents und die zwei Voll-Reviewer bekommen ihre Runde n+1 als
  Nachricht an ihre Agent-Id: 3 bis 5 Aufrufe statt 10 bis 15, und der
  Cache ist noch warm. Frisch gestartet wird, wenn die Worker-Session
  gewechselt hat, wenn die letzte Zeile des Agents im Prüfverlauf älter als
  60 Minuten ist, oder wenn der erste Brief inhaltlich falsch war. Die Ids
  stehen in `state.md` (`implementer_id`, `refactorer_id`, `logik_id`,
  `reviewer_ids`).
- `wt add <repo> <branch>` legt Branch, Worktree, herdr-Space und Bootstrap
  an: eigener Compose-Stack konfiguriert, eigene Ports, `vendor/` kopiert;
  keine Container, keine Datenbank, das macht erst `wt testdb` am
  Loop-Eintritt. Am Ende schreibt der Bootstrap `.wt-ready` in den
  Worktree, bei Fehler `.wt-failed`. Das ist eine Bereitschaftsmarke, kein
  Lock: `wt agent` wartet darauf, `/work` prüft sie vor dem ersten
  Loop-Durchlauf. Ältere Worktrees ohne Marke gelten als bereit, wenn
  `vendor/` und `.env` da sind.
- `wt agent <repo>/<branch-dir> [--resume|--fresh] -- <Prompt>` ist die
  Automatisierung, die `/lead` nutzt: startet Claude im Root-Pane des
  Spaces, wenn keiner läuft, oder spricht die laufende Session an.
  Verweigert, wenn der Worker arbeitet oder in einem Prompt hängt.
- Ich kann alles auch von Hand machen: `wt`, in den Space, `claude`, dann
  `/work RTM-xxxx`. `/work` liest immer `state.md` und `ticket.md`,
  deshalb ist egal, wer die Session gestartet hat.
- Eine Session pro Ticket: `/work` trägt seine Session-Id in `state.md`
  ein und stoppt, wenn eine andere Session dort steht und die Datei in den
  letzten zehn Minuten geschrieben wurde.
- Neu oder fortsetzen: `claude --continue` im Worktree setzt die letzte
  Session dieses Tickets fort. Fortsetzen bei Gate-Antwort oder Nacharbeit
  am selben Tag; frisch nach einem Tag Pause. Eine frische Session hat die
  Analyse nicht mehr im Kopf, aber in `ticket.md`; für eine tiefe
  Rückfrage liest sie die zitierten Stellen nach. `--fresh` auf eine
  laufende Session schickt `/clear`.
- Live-Test im Haupt-Checkout: `/worktree-move` (`wt main`) zieht den Branch
  in den Haupt-Checkout, `wt back` zurück.

## Tagesablauf

```
morgens   wt lead            → Space „lead" (cwd work-log), frische Session, /lead:
                               liest die letzte Tagesnotiz, wl, legt die heutige Notiz an,
                               /day morgen, Ticketliste, Worker starten (wt agent)
tagsüber  im Ticket-Space     → der Worker zeigt sein Gate, ich antworte dort
                               (/work RTM-x <…>), frage nach, diskutiere, lese
                               ticket.md; Permission-Prompts ebenfalls dort
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
`state.md` in Gitea (offen, nicht gemergt). Ein Worker-Bericht ist eine
Behauptung.

## Stolpersteine

- **Worker starten in `acceptEdits` statt `auto`:** Claude Code liest die
  `.claude/settings.local.json` eines Worktrees aus dem Haupt-Checkout, und
  Projekt-Settings schlagen die User-Settings. Steht dort
  `"defaultMode": "acceptEdits"`, gilt das für jeden Worktree. Die Zeile aus
  `~/code/RED-telematik-manager/RED-telematik-manager/.claude/settings.local.json`
  entfernen; `auto` kommt dann aus `~/.claude/settings.json`. herdr ist
  unschuldig, `herdr agent start` ruft `claude` ohne Flags auf.
- **Test-DB.** Hat bei RTM-3919, RTM-3776 und RTM-3836 je eine Runde oder
  einen Umweg über mich gekostet, weil Agents und Orchestrator eigene
  Docker- und Artisan-Befehle zusammengesetzt haben, die der Auto-Modus
  dann abgelehnt hat. Seit 2026-10-07 gibt es dafür genau einen Befehl:
  `wt testdb` (Container des Worktrees hoch, auf MariaDB warten, `migrate
  --seed --env=testing`; `--fresh` baut neu). `wt add` startet bewusst
  keine Container, ich nutze es auch von Hand; der Orchestrator ruft `wt
  testdb` einmal am Loop-Eintritt, jeder Agent nach einer neuen Migration
  oder einem Seeder. Der Befehl ist als Ganzes erlaubt. Taucht das Thema
  noch einmal auf, ist es ein Fehler in `wt testdb`, nicht in einem Brief.
- **Testumfang lokal.** Die Suite ist zu groß für diesen Rechner. Agents
  lassen nur die Tests der berührten Klassen und ihrer Aufrufer laufen, nie
  die Suite und keine breiten Sweeps über `tests/`. Ein Test anderswo, der
  in der CI rot wird (RTM-3836: `BelongsToConnectorTest` am neuen Index),
  ist Sache der CI und wird danach nachgezogen.

Weitere Umgebungs-Eigenheiten, die eine Runde gekostet haben (VPN,
Jira-Ausfall, Fixtures), gehören in die work-brain-Notiz
`pipeline-stolpersteine`. Der Lead liest sie beim Start, der Worker vor der
Analyse. Angelegt wird sie über `/brain`, sobald der erste echte Eintrag
da ist.

## Offene Punkte

- Rückmeldung zur Abnahme: im Chat (`nacharbeiten <Notiz>`) oder als
  Zeilenkommentare im PR (`nacharbeiten siehe PR`, der Worker liest sie
  nur). Beides geht; welcher Weg der normale wird, entscheide ich nach den
  ersten Tickets.
- **Neuer Fluss seit 2026-10-07, Versuch.** Anlass: RTM-3899 (9 Mio.
  Tokens für drei Zeilen), RTM-3919 (10,4 Mio., die Hälfte ohne Wirkung
  auf das Ergebnis; der einzige Architekturfehler kam aus der Spec-Phase,
  weil eine Scope-Frage als technisch galt und der Auditor sie vor mir
  entschied) und RTM-3883 (7,3 Mio., 44 % ohne Wirkung; der Planner hat den
  Code in Prosa geschrieben, der Implementer nur abgetippt; ein neues
  API-Feld wurde ohne Gate gebaut). In beiden Tickets null Ertrag der
  Review-Phase und der sieben Schritt-Prüfungen. Dazu die Beobachtung, dass
  die Agents gute Logik und schwache Architektur liefern, weil die Regeln
  im Kontext untergehen: daher der Refactorer als eigene Station.
  Messgrößen pro Ticket aus `wl --runden --sum` und `pruefung/befunde.md`:
  Cache-Tokens gesamt; Loop-Runden; Umbauten des Refactorers und ob eine
  Eskalation kam; Befunde des Logik-Reviews und des Voll-Reviews mit
  Schwere, davon umgesetzt, widerlegt, vom Worker gefixt; ob ich bei
  ABNAHME noch etwas zurückdrehen musste; ob eine Frage erst beim Bauen
  auftauchte. Zurück zum alten Flow: Commit `8433c20` (`pipeline`) in den
  dotfiles.
- **Auditor-Gedächtnis.** Der Auditor ist aus der Pipeline raus. Seine
  Musterdateien unter `~/.claude/agent-memory/auditor/` halten Urteile
  fest, die nie abgenommen wurden; das Verzeichnis kann weg.
- **Repo-Regel schärfen.** `.claude/rules/backend/architecture.md:34`
  erlaubt formal „fangen, Zustand setzen, weiterwerfen" in einer Aktion.
  Meine Haltung: eine Aktion reagiert nicht auf ihr eigenes Scheitern, der
  Aufrufer besitzt die Fehlerbehandlung. Bis das im Repo steht, prüft der
  Refactorer es als Fehlerbehandlungs-Eigentum.
- Ob der Lead kleine Operationen (Jira-Transition) nach Go selbst
  ausführen darf; Push und Merge bleiben in jedem Fall bei mir.
- Der Nachrichtenweg Lead ↔ Worker ist noch nicht im echten Lauf getestet:
  ob eine Nachricht an eine wartende Session dort wie eine Eingabe wirkt, und
  was passiert, wenn der Worker gerade in einem Permission-Prompt hängt.
