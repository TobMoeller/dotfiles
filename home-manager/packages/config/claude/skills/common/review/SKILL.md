---
name: review
description: Review a PR, diff, or branch against its linked ticket and write a grounded, severity-tagged review to .reviews/. Use when the user asks for a code review, PR review, or to review changes for a ticket (e.g. "review RTM-1234", "review this PR").
---

# Code review

Produce a codebase-grounded, PR-style review written to a file as the deliverable.

## 1. Get the ticket context first

If the user named a ticket (e.g. `RTM-1234`):

- Fetch its title, description, and **Definition of Done / acceptance criteria** via the Jira MCP.
- **If Jira is unreachable or token-scope-limited, do NOT retry repeatedly.** Stop and ask the user to paste the ticket content. One failed attempt is enough to fall back.

If no ticket is named, review against the diff alone and say so.

## 2. Read the diff and trace the real code

- Read the full diff (Gitea MCP if it's a PR, otherwise `git diff`).
- **Verify every finding against the actual codebase.** Open the surrounding code, follow the call paths, confirm behavior. Never speculate.
- If you cannot confirm something — failure handling, a deploy chain, whether an edge case is reachable — **say so explicitly** rather than asserting. A wrong confident finding is worse than a flagged uncertainty.

## 3. Run the tests

Features must be verified, not assumed. Run the tests relevant to the change and report the result. Run only what's needed to validate the diff — don't kick off unrelated, long, or destructive operations beyond what the suite itself does.

## 4. Write the review

Write to `.reviews/<ticket>.md` (or `.reviews/PR-<id>.md` if there's no ticket). Structure:

- **Summary** — what the change does, whether it meets the ticket's DoD (call out any gaps).
- **Findings** — each tagged `[blocker]` / `[major]` / `[minor]` / `[nit]`, with `file:line` references and a concrete suggested fix.
- **Open questions** — anything you couldn't confirm.

## 5. Optional: draft responses

If the user asks, draft reviewer comments — in **German** when the review is for the work team — for any open decisions or questions raised.

## Stay in scope

This is analysis, not a fix. Don't edit source files unless the user explicitly asks. Keep findings tight and idiomatic to the codebase's existing conventions; flag over-engineering rather than introducing it.
