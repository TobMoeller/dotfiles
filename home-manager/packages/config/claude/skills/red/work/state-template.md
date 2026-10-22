---
ticket: RTM-0000
title: <Jira-Titel>
type: bug              # bug | story | task
repo: RED-telematik-manager
branch: fix/RTM-0000/<slug>          # aus git, sobald /work im Worktree läuft
worktree: ~/code/worktrees/RED-telematik-manager/fix-RTM-0000-<slug>
phase: assess          # assess | build | review | accept | done | parked
gate: none             # none = läuft · open = wartet auf Tobias (siehe ## Gate) · passed = beantwortet
gate_id:               # FRAGEN (Fragen oder Umbau vor oder während des Baus) | ESK (Loop oder Voll-Review eskaliert: Bestands-Refactoring, Rundenlimit, Widerspruch zum Ticket) | PR (Tobias pusht, legt PR an) | ABNAHME
round: 0               # build: Loop-Durchlauf (1 = erster Bau, 2–3 = Nacharbeit nach Logik-Review) · review: Voll-Review-Runde (1–2)
discussion:            # <n> = Frage n wird im Worker-Space mit Tobias besprochen (/work §4a); leer = keine Diskussion
loop_base:             # git HEAD vor dem ersten Bau; Diff-Basis für Loop und Reviews ist `git merge-base origin/develop HEAD`
commits: auto          # auto = /work committet nach jedem Loop-Durchlauf und nach Fixes aus dem Voll-Review (Default, Tobias' stehende Entscheidung) · manual = /work staged nur (Tobias: `/work <T> commits manual`, `manual` in einer Gate-Antwort oder im Start-Prompt)
session:               # Claude-Session-Id des aktiven Workers (eine Session pro Ticket)
session_name:          # Name aus ListAgents, Adresse für SendMessage (vom Lead genutzt)
implementer_id:        # Agent-Ids dieser Session für Wiederholungsrunden per SendMessage (/work §0);
refactorer_id:         # nur gültig, solange session: dieselbe ist und die letzte Zeile des Agents
logik_id:              # in `wl <T> --runden` jünger als 60 Minuten ist
reviewer_ids:          # kommagetrennt, die zwei Voll-Reviewer
jira_status: <Status aus Jira>
pr:                    # Gitea-PR-URL sobald vorhanden
updated: 2026-01-01 00:00
---

# RTM-0000 — <Titel>

## Nächster Schritt

<Eine Zeile. Wer ist dran (KI oder Tobias) und was passiert als Nächstes.>

## Gate

<Leer, solange gate: none. Bei gate: open der Block aus /work §4: Kopf, TLDR-Satz, je offene Frage „Frage n · Titel" mit Hergang, Optionen, Empfehlung wörtlich aus ticket.md und → ticket.md#frage-n, Für dich zu tun, Antwort, Details; Leerzeilen zwischen den Blöcken, ≤20 Zeilen; darunter optional ### Beleg.>

## Offene Fragen

- [ ] F1 <Titel> · Klasse: <Klasse> · Gate: FRAGEN | ESK | ABNAHME · ticket.md#frage-1 · Empfehlung: <Option>
  (nur Index für `wl`; der Inhalt steht in ticket.md. Antworten auf Rückfragen stehen nirgends in Dateien, nur im Chat.)

## Commits

<nur bei commits: manual: eine Zeile pro Loop-Durchlauf bzw. Fix: `<Commit-Message>` · Dateien: …>

## Gates

| Gate | Was wird entschieden | Status | Datum | Notiz |
|---|---|---|---|---|
| FRAGEN | Fragen an Tobias und Umbau-Hinweise aus der Analyse (oder aus dem Bau heraus); Stopp nur wenn es welche gibt · Status `automatisch` oder `Tobias` | | | |
| LOOP | kein Stopp: Implementer → Refactorer → Logik-Review, bis kein major/blocker offen, max. 3 Durchläufe, dann ESK | | | |
| VOLL-REVIEW | kein Stopp: zwei unabhängige Reviewer über den ganzen Stand, Orchestrator führt zusammen und widerlegt; Kleinigkeiten fixt er selbst, Größeres geht in den Loop; max. 2 Runden, dann ESK | | | |
| PR | Tobias pusht und legt den PR an (kein Teil der Abnahme), Worker prüft lesend und postet den PR-Link in Jira | | | |
| ABNAHME | handover.md: Hergang der Änderung, Diff, DoD, Reviewer, offene Punkte, Commits, PR | | | |

## Log

- 2026-01-01 09:00 · assess · <ein Satz, was passiert ist>
