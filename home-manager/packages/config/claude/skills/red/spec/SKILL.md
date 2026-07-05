---
name: spec
description: Collaboratively define a detailed, implementation-ready backend specification for a task, through dialog. Gathers context from Jira (ticket/epic), Confluence, Figma, and the real codebase, then writes the spec to the central work-log store (~/code/knowledge/work-log/). Focuses on the backend (PHP) while accounting for the frontend structure it must serve. Use when the user wants to spec out, design, or plan a task before implementing it (e.g. "let's spec out RTM-1234", "spec this epic", "design the backend for this feature").
allowed-tools: Read Grep Glob Bash(git log:*) Bash(git diff:*) Bash(git show:*) Bash(git branch:*) Bash(git rev-parse:*) Bash(mkdir:*) Write Edit mcp__devtools-mcp__read_jira_issue mcp__devtools-mcp__search_jira mcp__devtools-mcp__get_jira_sprint mcp__devtools-mcp__link_jira_issues mcp__devtools-mcp__search_confluence mcp__devtools-mcp__read_confluence_page mcp__devtools-mcp__get_confluence_page_by_title mcp__claude_ai_Figma__get_design_context mcp__claude_ai_Figma__get_screenshot mcp__claude_ai_Figma__get_metadata mcp__claude_ai_Figma__get_variable_defs
---

# Backend specification (red / work)

Turn a task — a Jira ticket/epic, or a plain explanation — into a detailed, implementation-ready **backend** specification, through a **dialog** with the user. The spec is the artifact someone (you, later, or a teammate) implements from, so it must be grounded in the real ticket, the real design, and the real codebase — never invented.

This is a **conversation, not a one-shot**. Gather context, propose structure, surface the genuine decisions, and only commit them to the file once they're settled. Resolve open points by asking the user, not by guessing.

## Scope

- **Specify the backend.** The deliverable describes backend work (PHP — `app/`, `routes/`, `database/`, `config/`, jobs, events, services/actions, API contracts).
- **Account for the frontend, don't specify it.** Read the frontend (`resources/client/js/**`, `.vue`, `.ts`) and the Figma design to understand what the backend must serve — the data contract, the shapes the UI needs, the interactions that drive requests. Capture that as the **frontend-facing contract**, but do not design the frontend implementation.

## 1. Gather the inputs

Pull every source the user points at — combine them, don't pick one:

- **Jira ticket / epic** (e.g. `RTM-1234`): `read_jira_issue` for the description, acceptance criteria, and **Definition of Done**. For an **epic**, also read its child issues / linked issues so the spec covers the whole scope (or confirm with the user which children are in scope). The Jira MCP is often flaky — **make one attempt**, then ask the user to paste the content rather than retrying in a loop.
- **Figma** (a figma.com URL, or a view the user names): use the official Figma MCP — `get_screenshot` to see it, `get_metadata` for structure, `get_design_context` for the concrete fields/states/components, `get_variable_defs` for tokens. Extract what the backend must provide: the data shown, the states (empty/loading/error), the actions, the field-level constraints. **Make one attempt** per source; if it's unreachable, ask the user to describe or screenshot the view.
- **Confluence**: consult only when the task touches a documented design, domain convention, or decision you must align to (`search_confluence`, then `read_confluence_page` / `get_confluence_page_by_title`). Skip it otherwise.
- **A plain explanation**: when there's no ticket, work from the user's description — and offer to capture it as the spec's context section.

## 2. Ground in the real codebase

Before proposing anything, read the code so the spec fits what exists — don't design in a vacuum:

- **Backend**: find the relevant models, migrations, routes, controllers, actions/services, events, jobs, permissions, and existing tests. Note the conventions actually in use (how endpoints are shaped, how authorization is done, how async work is dispatched) so the spec extends them rather than inventing parallel patterns.
- **Frontend**: locate the Vue components/stores/API clients that will consume this work, to pin down the exact data contract the backend owes the UI.
- Cite `file:line` for anything the spec builds on or changes. If a claim is inference rather than confirmed from code, say so.

## 3. Discuss and decide — the dialog

This is the core of the skill. Drive an iterative conversation:

- Lead with a short **proposed shape** of the solution (the endpoints, the data model changes, the domain flow) so the user has something concrete to react to.
- Surface the **real decisions** explicitly — the forks where more than one reasonable approach exists, the ambiguities in the ticket, the gaps between the design and what the backend currently supports. Ask about these directly; recommend an option, don't just enumerate.
- Capture anything unresolved in **`open-questions.md`** rather than papering over it with an assumption. An assumption you do make goes in the spec under an explicit **Assumptions** heading.
- Iterate until the user is satisfied the spec is implementation-ready. Re-read code as decisions firm up.

## 4. Write the spec

The spec goes in the central **work-log** store, in one folder per ticket — co-located with that ticket's review if one exists. Resolve the store path from the **main repository name** (stable across the main checkout and all worktrees):

```bash
repo=$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")
mkdir -p ~/code/knowledge/work-log/"$repo"/<TICKET>
```

Write to `~/code/knowledge/work-log/<repo>/<TICKET>/spec.md`, where `<TICKET>` is the bare ticket id (e.g. `RTM-1234`); use a short kebab-case slug folder when there's no ticket. Keep unresolved items in `open-questions.md` in the same folder. Write incrementally as decisions settle — don't wait for the very end to commit anything to disk.

Structure `spec.md` roughly as:

```
# <TICKET-ID> — <Title>

## Context & goal
<what this is, why, links to the Jira ticket / epic / Figma / Confluence>

## Scope
In: …   Out: …

## Frontend-facing contract
<what the UI needs from the backend: the data, the states, the actions —
 grounded in the Figma view and the consuming Vue code (file:line)>

## API
<endpoints: method + path, request shape, response shape, status codes,
 auth/permission required — following existing route/controller conventions>

## Data model
<new/changed tables, columns, indexes, relationships, migrations>

## Domain logic
<services/actions, the flow, transaction boundaries, ordering of side effects,
 events/jobs/async work, external integrations>

## Validation & authorization
<request validation rules, permission keys, who may do what>

## Edge cases & error handling
<failure modes, partial-write safety, idempotency, empty/error states>

## Testing
<what to test and at which level — the cases that prove the DoD is met>

## Acceptance criteria / DoD mapping
<each DoD item → how this spec satisfies it; flag any the spec can't yet cover>

## Assumptions
<explicit assumptions made; anything still open lives in open-questions.md>
```

Adapt the headings to the task — drop sections that don't apply, add ones that do. Lead with substance over ceremony.

## Stay in scope

This is specification and planning, not implementation. **Do not change source files** in the project and don't post anything to Jira/Confluence/Figma — only write under `~/code/knowledge/work-log/`. Don't commit the store unless the user asks.
