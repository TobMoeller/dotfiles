---
name: tickets
model: opus
effort: low
description: Router to the team's Jira ticket skills in the shared ai-tooling repo (~/code/RED-telematik-manager/ai-tooling) — create a user story, split an oversized feature into an epic, file a QA-testable bug ticket, quality-gate a ticket before planning, or write the fachliche Spezifikation. Tells which team skill fits and how to run it in its own checkout (those skills need ai-tooling's CLAUDE.md and its tickets/<KEY>/ convention). Use when the user wants to create, split, refine, review or fix up a Jira ticket rather than implement one (e.g. "leg dafür ein Ticket an", "das Ticket ist zu groß", "Bug-Ticket schreiben", "ist RTM-1234 reif für die Umsetzung?").
argument-hint: "[story | epic | bug | review | spec] <Beschreibung oder RTM-XXXX>"
allowed-tools: Read Grep Glob Skill Bash(git status:*) Bash(git log:*) Bash(pwd)
---

# Tickets (red / work) — router to the team's ai-tooling skills

Ticket **creation and maintenance** is the team's domain and lives in the shared
repo `~/code/RED-telematik-manager/ai-tooling` (its own git repo, project-level
skills under `.claude/skills/`). Our own pipeline (`/work`, `/spec`,
`/pre-review`) starts **after** a ticket exists and deliberately bypasses the
ai-tooling implementation track. This skill only bridges the two worlds.

## Which team skill

| Need | Team skill | Input |
|---|---|---|
| Idea → user story (Als/möchte/um, Gherkin-AK, INVEST) | `feature-story-erstellen` | free text |
| Story too big → epic with vertically sliced stories | `epic-erstellen` | the oversized story |
| Bug report or code finding → QA-testable Jira bug (Bugfixing-Epic, components) | `bug-ticket-erstellen` | symptom / finding |
| Is the ticket clear, complete, testable? Quality gate with a verdict | `feature-ticket-review` | RTM key |
| Fachliche Spezifikation (WAS, nicht WIE) as `spezifikation.md` | `feature-spezifizieren` | RTM key |
| Collect, analyse and fix sub-bugs of a ticket one by one | `subbugs-abarbeiten` | RTM key |

Everything else in ai-tooling (planning, implementation, QA CSVs, UX/Figma,
docs) is **not** part of our flow — for planning and implementation use
`/work`.

## How to run one

Those skills depend on two things only their checkout provides: the project
`CLAUDE.md` with the `tickets/<KEY>/` folder convention, and tool names of the
team's MCP alias (`mcp__redicals__*` — the same devtools MCP we use as
`devtools-mcp`; the names in their `allowed-tools` only affect pre-approval,
not function). So:

1. **Already in the ai-tooling checkout** (`pwd` under
   `~/code/RED-telematik-manager/ai-tooling`)? Invoke the team skill directly
   with the Skill tool and pass the user's input through. Done.
2. **Anywhere else:** don't emulate the skill. Tell the user, in two lines,
   which skill fits and how to get there:

   ```
   prefix f → ai-tooling          # herdr/tmux project launcher opens the space
   claude                         # in that space
   /<team-skill> <Eingabe>
   ```

   The skill's local artifacts land in `ai-tooling/tickets/<KEY>/`
   (gitignored there). Nothing of that is copied into our work-log — the Jira
   ticket is the handover; `/work` reads it fresh in its assess phase.

## Coming from `/work`

`/work`'s assess phase routes here in three cases and then **stops** (a
`SPEC` gate in its `state.md` carries the instruction — ticket care is a
product question for Tobias, the only kind the `SPEC` gate stops for):

- ticket not implementable as written → `feature-ticket-review` (or
  `feature-spezifizieren` when the fachliche Spec is missing altogether),
- size `L` without an epic → `epic-erstellen`,
- a bug found while working a ticket that is out of scope →
  `bug-ticket-erstellen`, then continue the original ticket.

Record the detour in the ticket's `state.md` (`## Log` + `## Offene Fragen`)
so `/day` shows it as „wartet auf Ticket-Pflege".

## Stay in scope

This skill writes nothing and posts nothing. It never creates Jira issues
itself — that is exactly what the team skills are for, with their own checks.
