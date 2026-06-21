---
name: explain
description: Explain why code behaves a certain way by tracing the actual code path and citing file:line, cross-referenced with internal Confluence documentation. Use when the user asks how or why something works (e.g. "why does this job time out with no logs", "how does our KIM sync work", "what does the docs say about X").
---

# Code- and docs-grounded explanation (work)

Answer the *why* by reading the real code AND the team's internal documentation — never from memory alone. This is the work variant of `explain`; it adds Confluence to the sources.

## Trace the code

- Find and read the actual code path involved — your codebase, vendored framework/library source, config — and follow it to where the behavior is decided. Don't stop at the first plausible layer.
- For framework behavior (Laravel job timeouts, exception handling, Eloquent semantics, Elasticsearch mapping), read the framework source rather than describing it from memory.

## Check the internal docs

Search our Confluence for design docs, runbooks, and decisions relevant to the question, using the devtools MCP:

- `search_confluence` to find relevant pages
- `get_confluence_page_by_title` / `read_confluence_page` to read them

Use the docs to explain *intent* (why it was built this way, known constraints, agreed conventions) and reconcile them with what the code actually does. **If the docs and the code disagree, say so explicitly** — the discrepancy is often the real answer.

If Confluence is unreachable, don't retry in a loop — note that docs couldn't be consulted and answer from the code alone.

## Ground every claim

- Cite `file:line` for code, and link the Confluence page for documentation claims.
- If part of the answer is inference rather than confirmed from code or docs, say which part.
- Answer the *why* and the mechanism, contrasting concretely when the user is comparing two things.
- This is an explanation, not a refactor — don't change code unless asked.
