---
ticket: RTM-0000
title: <Jira-Titel>
type: story            # story | bug | task
size: M                # S | M | L  (S = Kurzspec, kein Schritt-Verifier; L = 3 Reviewer)
repo: RED-telematik-manager
branch: feat/RTM-0000/<slug>          # aus git, sobald /work im Worktree läuft
worktree: ~/code/worktrees/RED-telematik-manager/feat-RTM-0000-<slug>
phase: assess          # assess | spec | plan | implement | verify | review | accept | done | parked
gate: none             # none = läuft · open = wartet auf Tobias (siehe ## Gate) · passed = beantwortet
gate_id:               # SPEC (nur bei fachlicher Frage / Aufgabe vor dem Bauen) | PR (Tobias pusht, legt PR an) | ABNAHME | ESK (Auditor: Tobias entscheidet) | LIMIT (Rundenlimit)
step: 0/0              # implement: aktueller Schritt / Anzahl (inkl. Nacharbeit-Schritte)
round: 0               # Verifier-Runden im aktuellen Schritt bzw. Gate
discussion:            # <n> = Frage n wird im Worker-Space mit Tobias besprochen (/work §4b); leer = keine Diskussion
step_base:             # git HEAD beim Start des aktuellen Schritts
commits: auto          # auto = KI committet nach jedem verifizierten Schritt (Default, Tobias' stehende Entscheidung) · manual = KI staged nur (Tobias: `/work <T> commits manual`, `manual` in einer Gate-Antwort oder im Start-Prompt)
reviewers: 2           # 2 (Default) · 3 bei Größe L oder auf Wunsch
auditor: 0             # bisherige Auditor-Aufrufe (Obergrenze 2 pro Ticket)
session:               # Claude-Session-Id des aktiven Workers (eine Session pro Ticket)
session_name:          # Name aus ListAgents, Adresse für SendMessage (vom Lead genutzt)
analyst_id:            # Agent-Ids dieser Session für Wiederholungsrunden per SendMessage (/work §0);
planner_id:            # nur gültig, solange session: dieselbe ist und die letzte Zeile des Agents
verifier_id:           # in `wl <T> --runden` jünger als 60 Minuten ist
reviewer_ids:          # kommagetrennt
implementer_id:
jira_status: <Status aus Jira>
pr:                    # Gitea-PR-URL sobald vorhanden
updated: 2026-01-01 00:00
---

# RTM-0000 — <Titel>

## Nächster Schritt

<Eine Zeile. Wer ist dran (KI oder Tobias) und was passiert als Nächstes.>

## Gate

<Leer, solange gate: none (außer dem Entwurf für die Fragen-Prüfung, /work §4c). Bei gate: open der Block aus /work §4: Kopf, TLDR-Satz, je offene, geprüfte Frage „Frage n · Titel" + Kurzfassung wörtlich aus fragen.md + → fragen.md#frage-n, Für dich zu tun, Antwort, Details; Leerzeilen zwischen den Blöcken, ≤20 Zeilen; darunter optional ### Beleg.>

## DoD

- [ ] <Akzeptanzkriterium aus dem Ticket, ein Item pro Zeile · Nachweis: Testname oder „manuell: …" sobald verifiziert>

## Entscheidungen

- 2026-01-01 · <Entscheidung in einem Satz> (Quelle: Tobias | Analyst | Planner | Implementer | Auditor)

## Offene Fragen

- [ ] F1 <Titel> · Gate: SPEC | ABNAHME | ESK · Autor: Analyst | Auditor | Writer · fragen.md#frage-1 · Empfehlung: <Option>
- [ ] T1 <Titel> · spec.md#entscheidungen · Empfehlung: <Option>
  (nur Index. F = fachlich, Frage an Tobias in fragen.md, erst nach der Fragen-Prüfung im Gate. T = technisch, steht in spec.md unter Entscheidungen, der Auditor entscheidet. Antworten auf Rückfragen stehen nirgends in Dateien, nur im Chat.)

## Für Tobias

- [ ] <was nur Tobias tun kann: Prod-Zugriff, PO fragen, …> · <vor dem Bauen | vor dem Deploy> · Warum: …

## Commits

<nur bei commits: manual: eine Zeile pro verifiziertem Schritt: `<Commit-Message>` · Dateien: …>

## Gates

| Gate | Was wird entschieden | Status | Datum | Notiz |
|---|---|---|---|---|
| SPEC | Spec-Prüfung (plan-verifier Modus spec), technische Fragen (Auditor), Fragen-Prüfung (plan-verifier Modus fragen); Stopp nur bei geprüfter fachlicher Frage · Status `automatisch` oder `Tobias` | | | |
| CHECKS | DoD-Nachweise, Scope, Tests der berührten Klassen (Branch-Verifier, max. 2 Runden, kein Stopp) | | | |
| PR | Tobias pusht und legt den PR an (kein Teil der Abnahme), Worker prüft lesend | | | |
| ABNAHME | handover.md: Diff, DoD, Reviewer, offene Punkte, Commits, PR | | | |

## Log

- 2026-01-01 09:00 · assess · <ein Satz, was passiert ist>
