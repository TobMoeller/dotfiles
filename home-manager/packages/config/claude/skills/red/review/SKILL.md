---
name: review
description: Review a Gitea PR or the commits for a ticket — gathering context from Gitea, Jira (and Confluence when needed) — and write findings to the central reviews store (~/code/reviews/), each with a ready-to-paste friendly German PR comment plus a detailed rationale. Use when the user asks to review a PR, a ticket's changes, or commits (e.g. "review PR 1818", "review RTM-3122", "review the changes for RTM-3444"). Reviews backend (PHP) code by default; only inspects frontend code when the user explicitly asks for a frontend or full-stack review.
allowed-tools: Read Grep Glob Bash(git log:*) Bash(git diff:*) Bash(git show:*) Bash(git branch:*) Bash(git rev-parse:*) Bash(mkdir:*) Bash(vendor/bin/phpunit:*) Bash(vendor/bin/phpstan:*) Bash(vendor/bin/pint:*) mcp__devtools-mcp__get_gitea_pull_request mcp__devtools-mcp__get_gitea_pull_request_diff mcp__devtools-mcp__list_gitea_pull_request_files mcp__devtools-mcp__list_gitea_pull_request_commits mcp__devtools-mcp__list_gitea_pull_request_comments mcp__devtools-mcp__read_jira_issue mcp__devtools-mcp__search_jira mcp__devtools-mcp__search_confluence mcp__devtools-mcp__read_confluence_page mcp__devtools-mcp__get_confluence_page_by_title
---

# Code review (red / work)

Produce a codebase-grounded review written to `.reviews/`, where every finding ships with a friendly German comment to paste into the Gitea PR and a detailed rationale.

## 1. Determine what to review

Two input modes — pick based on what the user gave you:

- **A Gitea PR** (a PR number or URL): fetch it with the Gitea MCP.
  - `get_gitea_pull_request` for metadata (title, description, branch, linked ticket)
  - `get_gitea_pull_request_diff` for the diff, `list_gitea_pull_request_files` / `list_gitea_pull_request_commits` for scope
  - `list_gitea_pull_request_comments` so you don't repeat points already raised
- **A ticket number** (e.g. `RTM-1234`) with no PR: review the commits that reference it.
  - `git log --all --grep=RTM-1234 --oneline` to find the commits
  - Review their combined change: `git show <commit>` for one, or `git diff <base>..<head>` for a range
  - If the ticket maps to several commits or a branch, confirm the range with the user before reviewing.

If it's ambiguous which mode applies (or which PR/commits), **ask** before proceeding. Derive the ticket number from the PR title/branch when it isn't given explicitly.

## 2. Gather the ticket context

- Read the linked ticket via the Jira MCP (`read_jira_issue`) — pull the description and the **Definition of Done / acceptance criteria**.
- **If Jira is unreachable, make one attempt then stop** and ask the user to paste the ticket content. Do not retry in a loop.
- Consult **Confluence only when needed** — i.e. the change touches a documented design/convention you must check it against (`search_confluence`, then `read_confluence_page` / `get_confluence_page_by_title`). Skip it otherwise.

## 3. Review against the real code

- **Scope: backend only by default.** Review backend code (PHP — `app/`, `routes/`, `database/`, `config/`, `tests/`, …). Do **not** raise findings on frontend code (`resources/client/js/**`, `.vue`, `.ts`) unless the user explicitly asks for a frontend or full-stack review. When you skip frontend changes, note it in one line in the summary so it's clear the FE side was out of scope and can be requested separately.
- Verify every finding against the actual codebase — open the surrounding code, follow the call paths, confirm behavior. **Never speculate.** If you cannot confirm something (failure handling, a deploy path, reachability of an edge case), say so explicitly rather than asserting it.
- Check the change against the ticket's DoD and call out any gaps.
- **Be selective.** Prefer high-confidence correctness, architectural/structural, and convention issues over enumerating every minor style nit. A couple of `nit`s are fine — don't pad the review with low-value trivia.
- **Apply a structural/architectural lens, not just a "is it mechanically detectable" lens** — this is where the highest-value findings hide:
  - Action/service classes that mix DB writes with notifications/dispatch → check transaction boundaries, ordering of irreversible side effects (e.g. broadcasts/webhooks before commit), partial-write / orphan-record safety, and whether async work belongs in the scheduler rather than dispatched inline.
  - New DB columns holding an external-system reference → check whether the name signals that, vs. looking like a local FK.
  - Route names ↔ permission keys ↔ URL paths → check they stay consistent with each other and with sibling endpoints.
- Keep findings tight and idiomatic to the codebase's conventions; flag over-engineering rather than introducing it.

## 4. Verify with tests and static checks

Features must be verified, not assumed — but **never run the full test suite**. Run only the tests relevant to the change, using the phpunit executable directly (not `php artisan test`):

- `vendor/bin/phpunit path/to/RelevantTest.php` — the test files covering the changed classes
- `vendor/bin/phpunit --filter <TestName>` — to narrow to the specific cases that exercise the change
- map the changed files to their corresponding test files/directories and run just those

Then run the static checks. These are fast, so run them across the **whole project** (no need to scope them):

- **PHPStan:** `vendor/bin/phpstan analyse` — full static analysis.
- **Pint (test mode):** `vendor/bin/pint --test` — checks code style across the project without modifying anything.

Report the result of each. A failing test, a PHPStan error, or a Pint style violation in the changed code is itself a finding — include it in the review. Only the **test suite** must stay scoped (it runs too long otherwise); PHPStan and Pint can run in full.

## 5. Write the review

Write to the central reviews store, **not** into the checkout (a `.reviews/` inside a worktree is destroyed by `wt rm`). The target is `~/code/reviews/<repo>/<ticket>.md` (or `.../PR-<id>.md` when there's no ticket), where `<repo>` is the main repository name — stable across the main checkout and all its worktrees. Resolve and create it with:

```bash
repo=$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")
mkdir -p ~/code/reviews/"$repo"
```

Then write to `~/code/reviews/$repo/<ticket>.md`. Start with a short summary: what the change does, and whether it meets the DoD (note gaps).

Then one section per finding, in this exact shape:

```
### [blocker|major|minor|nit] Kurzer Titel — `path/to/File.php:42`

(Das Severity-Tag bleibt NUR hier im Titel — als Bewertung/Triage. Es kommt NICHT in den Gitea-Kommentar.)

**Gitea-Kommentar (zum Kopieren):**
> <kurz (1–4 Sätze), kollegial, tentativ — hedgend ("Ich glaube …", "vermutlich", "eventuell");
> als konkreter Vorschlag ODER ehrliche Frage; nenne konkrete Alternative(n) bzw. eine bestehende
> Lösung im Code beim Namen; Trivia mit "nit:" beginnen; Optionales/Außer-Scope explizit als
> "kein Muss" markieren und ggf. ein Ticket vorschlagen; Dubletten per Link auf den ersten
> Kommentar statt Wiederholung. KEINE [major]/[minor]-Klammern im Kommentar.>

**Kontext (für dich, nicht zum Posten):**
<knapp: Ursache, konkrete Auswirkung, empfohlener Fix — mit file:line und ggf. Confluence-Doku;
nur so lang wie nötig>
```

Guidance for the two parts:

- **Gitea-Kommentar** — the copy-paste deliverable, and it must read like *this reviewer's* voice: short (1–4 sentences), collegial, tentative. Hedge ("Ich glaube …", "vermutlich", "eventuell"), offer concrete options ("Eventuell X? Oder Y."), and name existing code/solutions by their real path (e.g. `App\Service\Firmware\Sorts\VersionSort`). Prefix trivia with `nit:`. For optional or out-of-scope points, say so explicitly ("kein Muss") and suggest opening a ticket. Cross-reference a duplicate with a link to the first comment instead of repeating it. Never put a `[major]`/`[minor]` tag in the comment — the severity lives only in the finding title.
- **Kontext** — for the user's understanding, not for posting: root cause, concrete impact (bug, security, performance, maintainability), recommended fix, grounded in `file:line` and any relevant Confluence doc. Keep it as short as the point allows.

The severity tag (`[blocker|major|minor|nit]`) stays in the finding **title** as the rating — only keep it out of the pasted comment.

End with an **Offene Fragen** section for anything you couldn't confirm.

## Stay in scope

This is analysis, not a fix. Don't edit source files and don't post anything to Gitea yourself — the German comments are for the user to paste. Only write the review file under `~/code/reviews/`.
