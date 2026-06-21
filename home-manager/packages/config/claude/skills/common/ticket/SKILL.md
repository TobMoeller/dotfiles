---
name: ticket
description: Pull a Jira ticket's full context (description, acceptance criteria, Definition of Done) into the conversation, with a paste fallback when the connector is down. Use when the user references a ticket ID and you need its requirements (e.g. "what does RTM-1234 ask for", "load ticket RTM-1234").
---

# Load ticket context

Get the requirements for a ticket reliably, even when the Jira connector is flaky.

## Fetch

Use the Jira MCP to retrieve, for the given ticket ID:

- Title and description
- Acceptance criteria / **Definition of Done**
- Status, type, and any linked issues that affect the work

## Fallback fast — don't retry the connector

The Jira MCP is frequently unreachable or token-scope-limited. **Make one attempt.** If it fails:

- Do **not** retry in a loop or improvise around the missing requirements.
- Ask the user to paste the ticket title, description, and DoD directly.
- Proceed from the pasted content.

## Output

Summarize the requirements concisely and call out the **Definition of Done as an explicit checklist** — this is what downstream work (a fix, a review) gets measured against.
