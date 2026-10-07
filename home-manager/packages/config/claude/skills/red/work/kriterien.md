# Fertig-Kriterien der Pipeline

Was ein Artefakt erfüllen muss, damit die nächste Phase beginnt. Die Listen
gelten für jedes Ticket gleich; sie werden hier gepflegt, nicht vom Agenten
pro Ticket erfunden. Ein Verifier beantwortet jede Zeile mit ja oder nein.
Nur ein Nein ist ein Befund, der eine Runde kostet; alles andere, was dem
Verifier auffällt, ist ein Hinweis und wird mitgegeben, nicht zurückgegeben.
Die fachlichen Kriterien (was gebaut wird) kommen aus dem Ticket; die
Verifier prüfen gegen das Ticket selbst, nicht gegen die Abschrift des
Analysten.

## S1–S6 · Spec fertig (`plan-verifier`, Modus spec)

| Nr | Kriterium | Woran geprüft wird |
|---|---|---|
| S1 | Jedes Akzeptanzkriterium und jedes DoD-Item des Tickets steht in `## DoD` und wird von der Spec behandelt; nichts ist weggelassen oder umgedeutet | Ticket (Jira) gegen `state.md ## DoD` und `spec.md` |
| S2 | Die drei Annahmen, auf denen die Lösung ruht, stimmen am Code (Klasse, Methode, Relation, Verhalten existieren und tun, was die Spec sagt) | `file:line`-Stichprobe |
| S3 | Scope ist benannt: was in ist, was out ist; „out" lässt nichts fallen, was das Ticket verlangt; wird der Scope erweitert, dann um die ganze Gruppe gleichartiger Lücken, eine Teilmenge nur mit Grund und mit jeder ausgelassenen Lücke in der Frage an Tobias | `spec.md ## Scope` bzw. `## Diagnose` gegen Ticket und Sweep des Analysten |
| S4 | Jede Annahme über echte Daten (gibt es die Fälle, wie viele, in welcher Form) steht als Aufgabe für Tobias mit fertigem Statement, Klasse `Daten`, vor dem Bauen | `## Für Tobias`, `fragen.md` |
| S5 | Jede offene Frage ist eingeordnet (Klasse, siehe `/work` §4c) und steht am richtigen Ort: Fragen an Tobias in `fragen.md`, technische als `T<n>` in der Spec | `## Offene Fragen`, `fragen.md`, `spec.md ## Entscheidungen` |
| S6 | Jedes DoD-Item hat eine Teststrategie (Testname oder „manuell: <Schritt>") | `spec.md ## Testing`, DoD-Mapping |

Immer Hinweis, nie Befund: TLDR-Formulierung (`[sprache]`), Stil, Alternativen, die die Spec nicht schlechter machen.

## P1–P6 · Plan fertig (`plan-verifier`, Modus plan)

| Nr | Kriterium | Woran geprüft wird |
|---|---|---|
| P1 | Jedes DoD-Item hat einen Schritt und einen benannten Test, oder ein explizites „manuell: <Schritt>" | `plan.md ## DoD-Mapping` gegen `state.md ## DoD` |
| P2 | Kein Schritt berührt Dateien oder Verhalten außerhalb der Spec; die genannten Dateien existieren oder werden vom Plan angelegt | Dateien öffnen |
| P3 | Keine Entscheidung ist stillschweigend getroffen: jede Frage in `## Offene Fragen` ist abgehakt oder hat eine Zeile in `## Entscheidungen` | `state.md` |
| P4 | Die Schritte halten die Repo-Regeln der berührten Pfade ein (Architektur, Namen, Testkonventionen, Commit-Format) | `.claude/rules/**` |
| P5 | Jeder Schritt lässt die Suite für sich grün; kein Schritt hängt von einem späteren ab | Reihenfolge lesen |
| P6 | Die zwei riskantesten Schritte stimmen am Code (Klasse, Methode, Relation existieren und verhalten sich wie angenommen) | `file:line`-Stichprobe |

## I1–I5 · Schritt fertig (`step-verifier`, Modus schritt)

| Nr | Kriterium | Woran geprüft wird |
|---|---|---|
| I1 | Jede geänderte Datei gehört zum Schritt oder ist sein Test | `git diff`, untracked |
| I2 | Der Code tut, was der Schritt sagt: nichts fehlt, nichts ist dazugekommen, keine Abweichung von `## Entscheidungen` | Diff gegen `plan.md` |
| I3 | Der benannte Test existiert, läuft über den geänderten Pfad und würde ohne die Änderung rot | Test lesen |
| I4 | Checks grün, selbst gelaufen: PHPStan, Pint, der Test des Schritts; Frontend `npm run lint`, `type-check` | Ausführen |
| I5 | Regeln der berührten Pfade eingehalten; kein Logikfehler mit heute erreichbarem Szenario (falsche Daten, Autorisierungslücke, Seiteneffekt vor Commit, N+1) | `.claude/rules/**`, Code |

## B1–B5 · Branch fertig (`step-verifier`, Modus branch, das CHECKS-Gate)

| Nr | Kriterium | Woran geprüft wird |
|---|---|---|
| B1 | Jedes DoD-Item hat einen Nachweis: ein grüner Test, den der Verifier selbst gelaufen hat, oder „manuell: <Schritt>" | `state.md ## DoD` |
| B2 | Keine Datei außerhalb der Vereinigung aller Plan-Schritte | `git diff <merge-base>` |
| B3 | Die Tests jeder berührten Klasse und ihrer per Grep gefundenen Aufrufer sind grün | Ausführen |
| B4 | PHPStan und Pint auf allen geänderten PHP-Dateien grün | Ausführen |
| B5 | I5 über den ganzen Diff, kurz; die Review-Phase geht tiefer | Code |

## Review (`reviewer`)

Kein Fertig-Kriterium: die Review-Runde führt alles auf, was auffällt. Was
davon bleibt, entscheidet der Widerlege-Schritt und das Register, nicht der
Reviewer selbst.
