---
name: tickets
model: opus
effort: low
description: Router to the team's Jira ticket skills from the shared ai-tooling repo, which are linked into ~/.claude/skills by name and run directly in any session — create a user story (feature-story-erstellen), split an oversized feature into an epic (epic-erstellen), file a QA-testable bug ticket (bug-ticket-erstellen), maintain the in-app docs (feature-doku-pflegen). Says which one fits and invokes it with the user's input; never emulates them. Use when the user wants to create, split or file a Jira ticket, or document a feature, rather than implement one (e.g. "leg dafür ein Ticket an", "das Ticket ist zu groß", "Bug-Ticket schreiben", "Doku für X pflegen").
argument-hint: "[story | epic | bug | doku] <Beschreibung oder RTM-XXXX>"
allowed-tools: Read Skill
---

# Tickets (red / work) — router to the team's skills

Ticket **creation and maintenance** is the team's domain. Its skills live in
the shared repo `~/code/RED-telematik-manager/ai-tooling`; the four we use
are linked by name into `~/.claude/skills` (`claudeExternalSkills` in
`red-tobias.nix`), so they are available in every session, including a
`/work` worker in its worktree. No checkout change, no subagent, no
emulation: invoke the team skill with the Skill tool and pass the input
through. Our own pipeline (`/work`) starts after a ticket exists.

| Need | Team skill | Input |
|---|---|---|
| Idea → user story (Als/möchte/um, Gherkin-AK, INVEST) | `feature-story-erstellen` | free text, or the facts of a Nebenbefund |
| Story too big → epic with vertically sliced stories | `epic-erstellen` | the oversized story |
| Bug report or code finding → QA-testable Jira bug (Bugfixing-Epic, components) | `bug-ticket-erstellen` | symptom, Hergang, Fundstellen |
| In-app documentation (`resources/docs/*.json`) for a feature | `feature-doku-pflegen` | RTM key or area; run from the product repo or a worktree |

Each of them shows the full draft and creates the issue only after an
explicit go (`create_jira_issue` is a prompted write here); they search
duplicates, pick the Bugfixing-Epic, set components, assignee and the
Produkt field themselves, and link a Herkunftsticket. They need no file
from ai-tooling: the shared sections are inlined in every skill by the
team's convention. Their tool names come without the MCP prefix; our
server is `devtools-mcp`.

## From inside a `/work` worker

The orchestrator has the whole context (Hergang, Fundstellen, Scope, the
discussion), so it runs the team skill itself: `Skill(bug-ticket-erstellen)`
or `Skill(feature-story-erstellen)` with the facts as argument, answers
the skill's questions from `ticket.md` where it can and asks Tobias the
rest in the chat, shows the draft, creates on his go, links the new key to
the ticket and records it in `ticket.md ## Entscheidungen`. It never sends
Tobias to another checkout and never spawns an agent for it.

## Not linked, on purpose

The rest of ai-tooling: its implementation track (`dev-feature-plan`,
`dev-feature-implement`, `implementierung`, `be-/fe-plan-erstellen`,
`feature-implementierungsplan`, `feature-plan-review`,
`abhaengigkeiten-pruefen`, `grill-me`) is replaced by `/work`;
`feature-ticket-review` and `feature-spezifizieren` write
`tickets/<KEY>/spezifikation.md` under ai-tooling and are covered by the
analysis in `/work` (`ticket.md`); `subbugs-abarbeiten` is an
implementation orchestrator; `feature-qa-tests` and
`feature-rtm-testfall-erstellen` produce QA artefacts (TestRail) that QA
owns; `jira-ticket-lesen` is our `/ticket`; `pr-review-frontend` posts its
review to Gitea itself and reviews with one agent, so its useful core (nine
Vue 3 error classes) lives in our reviewer profile as the frontend section
instead, used by `/review` on request; `git-*`, `skill-anlegen`,
`learn`, `ux-*`, `figma-screens-erstellen` are outside our flow. To link
one later: add it to `claudeExternalSkills` and switch.

## Stay in scope

This skill writes nothing and posts nothing itself. It routes to the team
skill, which carries the checks and the Freigabe.
