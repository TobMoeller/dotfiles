---
name: brain
description: Read from or write to the personal/work AI second brain (Open Knowledge Format markdown stores). Use to look up stored knowledge, file new knowledge (ingest), or health-check the store (lint). Examples: "what's in the brain about the billing API", "file this into the brain", "remember how we fixed the webhook retries", "lint the brain".
---

# Second brain (OKF)

Two markdown knowledge stores, each governed by its own `SCHEMA.md`, living side by side under the `~/code/knowledge/` Obsidian vault:

- **`~/code/knowledge/brain`** — personal / non-confidential (reference, snippets, practices). Its `notes/` subfolder is a **freeform, human-only** zone — don't maintain it or index it here; only work in `notes/` if the user explicitly asks.
- **`~/code/knowledge/work-brain`** — work / RED Medical (APIs, runbooks, domain, practices).
  Confidential: never store secrets or customer data; never push to a personal remote.

This skill is for **durable, recall-oriented knowledge** only. Per-ticket task artifacts (code reviews, specs) are not knowledge — they live in the sibling `~/code/knowledge/work-log/` store, written by the `review` / `spec` skills. A learning distilled *from* such an artifact can be ingested here; the artifact itself stays in work-log.

**Always read the target store's `SCHEMA.md` first** — it holds the authoritative
format, folder layout, and commit policy. This skill is the entry point; SCHEMA.md
is the manual.

## Choosing the store (routing)

- Work-/RED-/company-/internal-API-related knowledge → **work-brain**.
- General/personal/cross-project knowledge → **brain**.
- The user may name it explicitly (`/brain ... work`).
- **If genuinely ambiguous, ask** — never risk filing work knowledge into the
  personal store, or vice versa.

## Modes

### Query (look something up)
1. `grep`/read the store's `index.md` and concept `description`s for relevance.
2. Read matching concept files.
3. Answer with citations (`apis/billing.md`). If the answer was valuable and not
   already captured, offer to ingest it.

### Ingest (file knowledge)
1. Read the source (pasted text, a solved problem, an article, an OneNote dump).
2. Decide new concept vs update existing — **prefer updating** over duplicating.
3. Write/update the concept file with correct frontmatter (`type`, `title`,
   `description`, `tags`, `timestamp`, optional `resource`) per SCHEMA.md.
4. Update `index.md` (one-line entry under the right group).
5. Append a line to `log.md` (`## [YYYY-MM-DD] ingest | <summary>`).
6. Commit the store (see below).

Only capture what's **non-obvious or hard-won**. Don't duplicate what a codebase
already states — link/summarize instead. Never store secrets or customer data.

### Lint (health check)
Scan for contradictions, stale `timestamp`s, orphan pages (nothing links to them),
missing cross-links, and `description` drift. For **work-brain**, also scan for
accidentally-committed secrets or customer data. Propose fixes; don't apply
destructive changes without confirming.

## Committing

These stores are the exception to the global "commit only when asked" rule:
**auto-commit after writing**, with a short message (`ingest: <topic>`,
`update: <topic>`, `lint: <summary>`). Small and frequent. **Never push**
automatically — pushing (especially work-brain) is always manual.

## Bootstrapping a brain that doesn't exist yet

If a target store directory is missing on this machine, say so rather than
inventing one — it may simply not be set up on this host.
