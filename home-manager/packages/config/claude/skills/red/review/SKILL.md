---
name: review
description: Review a Gitea PR or the commits for a ticket — gathering context from Gitea, Jira (and Confluence when needed) — and write findings to the central work-log store (~/code/knowledge/work-log/), each with a ready-to-paste friendly German PR comment plus a detailed rationale. Use when the user asks to review a PR, a ticket's changes, or commits (e.g. "review PR 1818", "review RTM-3122", "review the changes for RTM-3444"). Reviews backend (PHP) code by default; only inspects frontend code when the user explicitly asks for a frontend or full-stack review.
allowed-tools: Read Grep Glob Bash(git log:*) Bash(git diff:*) Bash(git show:*) Bash(git branch:*) Bash(git rev-parse:*) Bash(mkdir:*) Bash(vendor/bin/phpunit:*) Bash(vendor/bin/phpstan:*) Bash(vendor/bin/pint:*) mcp__devtools-mcp__get_gitea_pull_request mcp__devtools-mcp__get_gitea_pull_request_diff mcp__devtools-mcp__list_gitea_pull_request_files mcp__devtools-mcp__list_gitea_pull_request_commits mcp__devtools-mcp__list_gitea_pull_request_comments mcp__devtools-mcp__read_jira_issue mcp__devtools-mcp__search_jira mcp__devtools-mcp__search_confluence mcp__devtools-mcp__read_confluence_page mcp__devtools-mcp__get_confluence_page_by_title
---

# Code review (red / work)

Produce a codebase-grounded review written to the central `work-log` store, where every finding ships with a friendly German comment to paste into the Gitea PR and a detailed rationale.

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
  - **Dead / unnecessary / speculative code** → does every new class, method, branch, config key, or middleware actually earn its place? The sharpest smell is code that is **inert as shipped** — effort with zero effect: config that makes its own consumer a no-op (e.g. an empty allowlist that turns a middleware into a pass-through, like `AllowIps` with empty `allowed_ips` and no env wiring), branches unreachable on any real call path, dead endpoints. Flag those. **But do not confuse "no caller yet" with "unnecessary":** a class that faithfully models a first-class concept of the external system/API being integrated (e.g. a Prometheus metric type like `Counter`/`Histogram`) is completing a domain model, not speculating — it's legitimate even with no producer yet, especially if cheap and covered by a contract test. Reserve the YAGNI flag for *internal* abstractions with no consumer *and* no domain justification. Always trace actual callers/reachability before flagging — confirm, don't assume — and separate "carried over verbatim from the replaced code" (note it, lower severity) from "newly introduced and already unused".
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

Write to the central work-log store, **not** into the checkout (a `.reviews/` inside a worktree is destroyed by `wt rm`). The target is `~/code/knowledge/work-log/<repo>/<TICKET>/review.md` — one folder per ticket, co-located with its spec if one exists. Use `rereview.md` in the same folder for a follow-up pass, and a slug folder (e.g. `PR-<id>/review.md`) when there's no ticket. `<repo>` is the main repository name — stable across the main checkout and all its worktrees. Resolve and create it with:

```bash
repo=$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")
mkdir -p ~/code/knowledge/work-log/"$repo"/<TICKET>
```

Then write to `~/code/knowledge/work-log/$repo/<TICKET>/review.md`.

### 5a. Start with the overall review comment

Begin the file with a short **status block** for yourself (what the change does; DoD met / gaps; PHPStan/Pint/test results) — this stays in the file.

Then, under a **`## Gesamt-Kommentar (zum Kopieren)`** heading, write a **paste-ready top-level PR review comment in the reviewer's voice** — this is what gets posted as the overall review, separate from the line comments. Model it on how this reviewer actually opens a review:

1. **Genuine praise first**, and confirm the ticket goal is met ("Das sieht prinzipiell alles schonmal ganz gut aus und die Ticket-Probleme dürften damit behoben sein …").
2. If applicable, honestly name that some things were hard to follow ("allerdings ist es mir beim Durchgehen schwergefallen, ein paar Dingen zu folgen").
3. The **2–4 biggest architectural/structural impressions as a numbered list** with **bold one-line headers**, each written in the first person ("Es fiel mir schwer …", "Mich stört dabei weniger, *dass* …, als dass …", "Am meisten wünsche ich mir …"). These are the high-value themes — cross-cutting design, naming collisions, over-complex indirection, a missed abstraction — not line nits.
4. Close by **de-escalating**: state plainly that none of it is a hard blocker if that's true ("Nichts davon ist für mich ein harter Blocker.").

If you leaned on the AI to structure this, it's fine to say so in the reviewer's actual style ("hab das mal von der KI zusammenfassen lassen 😄") — this reviewer does that openly.

### 5b. Then one section per finding, in this exact shape

```
### [blocker|major|minor|nit] Kurzer Titel

📍 **`path/to/File.php:42`** · `methodOrSymbolName()` <— zur Orientierung, wo der Kommentar hingehört

(Das Severity-Tag bleibt NUR hier im Titel — als Bewertung/Triage. Es kommt NICHT in den Gitea-Kommentar.)

**Gitea-Kommentar (zum Kopieren):**
> <SEHR kurz — in der Regel 1–2 Sätze, hart bei max. 4. Am liebsten eine ehrliche Frage
> ("Brauchen wir …?", "Sind die Tests bewusst …?") ODER ein konkreter Vorschlag mit benannter
> Alternative ("Alternativer Namensvorschlag: `konnektor_routes_faulty`. Und dann auch wieder
> ohne `status` Label."). Erste Person, kollegial, hedgend ("Ich glaube …", "vermutlich",
> "eventuell", "oder?"), Emoji sparsam ok (😄). Trivia mit "nit:". Optionales/Außer-Scope
> explizit entschärfen ("kein Muss", "können wir auch in einem anderen Ticket"). Dubletten per
> Link auf den ersten Kommentar statt Wiederholung. KEINE [major]/[minor]-Klammern.>

<NUR wenn eine tiefere/längere Analyse dahinter steckt (Cardinality, PromQL, Trade-offs …):
NICHT in die kurze Zeile oben pressen. Stattdessen den kurzen menschlichen Kommentar behalten
UND die Detailanalyse als klar ALS KI-Vorschlag ausgewiesenen, ausdrücklich optionalen Block
anhängen — so postet dieser Reviewer das tatsächlich:>

> Die KI hat hier noch einen (mMn.) interessanten Vorschlag gemacht. Muss man nicht aufnehmen,
> fand's nur spannend:
> <hier der Detailblock — gern mit Code/PromQL-Beispiel>

**Kontext (für dich, nicht zum Posten):**
<knapp: Ursache, konkrete Auswirkung, empfohlener Fix — mit file:line und ggf. Confluence-Doku;
nur so lang wie nötig>
```

Guidance for the parts:

- **Location line (📍)** — put it on its **own line directly under the title**, not buried in the title. Bold `path:line` plus the enclosing method/class/symbol so the reviewer can find the exact spot to attach the comment in Gitea at a glance. Every finding gets one.
- **Gitea-Kommentar** — the copy-paste deliverable, and it must read like *this reviewer's* voice, which is **shorter than you think**: usually **one or two sentences**, often just a genuine question or one concrete rename/alternative. Look at the calibration examples below and match that length and tone. Hedge, name existing code/solutions by their real path (e.g. `App\Service\Firmware\Sorts\VersionSort`), prefix trivia with `nit:`, mark optional/out-of-scope explicitly ("kein Muss"), and suggest a follow-up ticket where it fits. Cross-reference duplicates with a link. Never a `[major]`/`[minor]` tag in the comment.
- **Deeper analysis → attributed optional block.** Do **not** inflate the reviewer's own short comment with a wall of technical reasoning. Keep the human comment tight, then, if the point rests on deeper analysis, append it as a clearly **AI-attributed, explicitly optional** block ("Laut KI …", "Die KI plädiert hier relativ stark für ein Histogram 😄", "Muss man nicht aufnehmen, fands nur spannend:"). This two-tier split — short human ask + attributed optional deep-dive — is exactly how this reviewer posts.
- **Kontext** — for the user's understanding, not for posting: root cause, concrete impact (bug, security, performance, maintainability), recommended fix, grounded in `file:line` and any relevant Confluence doc. Keep it as short as the point allows.

The severity tag (`[blocker|major|minor|nit]`) stays in the finding **title** as the rating — only keep it out of the pasted comment.

### 5c. Voice calibration — real examples of this reviewer's comments

Match this register and length. These are the target; the wall-of-text paragraph is the anti-pattern.

- Middleware/config no-op → *"Brauchen wir diese Middleware und den dazugehörigen Config Eintrag? In der Config ist es eine statische leere Liste, das hat also keinen Effekt."*
- Duplicated construction → *"Die `CollectorRegistry` wird im `MessageBrokerServiceProvider` quasi identisch nochmal gebaut. Vielleicht wäre es besser, diese nur einmal als Singleton zu definieren anstatt sie hier an die ServiceProvider-Instanz zu hängen."*
- Naming + concrete alternative → *"Wäre als Name nicht etwas wie `konnektor_registration_card_missing` besser? Hier werden ja nicht mehr unterschiedliche Status über das Label abgebildet … Das `status` Label wäre dann auch obsolet."*
- Test placement question → *"Sind die Tests bewusst in dem `Unit` Verzeichnis gelandet? Ich glaube die Trennung wurde bisher nicht absolut konsistent durchgezogen …"*
- nit → *"nit: Hier wäre eventuell auch ein Name mit `_count` passender, oder?"*
- Deep AI suggestion (attributed, optional) → *"Die KI plädiert hier relativ stark für ein Histogram 😄:"* followed by the detailed block.

End with an **Offene Fragen** section for anything you couldn't confirm.

## Stay in scope

This is analysis, not a fix. Don't edit source files and don't post anything to Gitea yourself — the German comments are for the user to paste. Only write the review file under `~/code/knowledge/work-log/`.
