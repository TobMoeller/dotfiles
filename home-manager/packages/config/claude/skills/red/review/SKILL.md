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
- **Be selective.** Prefer high-confidence correctness, architectural/structural, and convention issues over enumerating every minor style nit.
- **Every `nit` needs a real problem behind it — at minimum a violation of the repo's own rules** (`.claude/rules/**`: `where()` without an explicit operator, a class constant without a type, a `shouldReceive` without `withArgs`, a comment referencing a ticket, …). Name the rule it breaks so the author can see it is not a matter of taste. Pure preference ("I'd have named this differently", "this could be one line shorter") is not a nit, it is padding — cut it. Nits are welcome; unanchored ones are not.
- **Behaviour beats symmetry.** A finding earns its place when something can actually go wrong: wrong data, a record stuck in the wrong state, an unreachable branch, a blocked retry, a permission hole. Findings whose entire argument is "this is a 1:1 copy of X", "this is inconsistent with the sibling implementation" or "the order differs from the existing controller" get dropped by this reviewer almost every time. Raise a duplication/asymmetry point only when you can name the concrete consequence (a future fix that will land in one copy and not the other, an explanatory comment lost in the copy that makes the new code read like a bug) — and then lead with that consequence, not with the symmetry.
- **A finding needs a realistic trigger, not a chain of preconditions.** "If the enum ever grows", "unless the queue order is guaranteed", "in the worst case, if every call runs into its timeout" — such findings are technically correct and still do not get posted. Before a finding goes in, ask: what has to coincide for this to happen, and is that a normal operating case? If the answer contains more than one improbable precondition, it belongs in the `Kontext` block at most, not in a comment. The findings this reviewer actually posts describe something that goes wrong **today** (a defect reproducible from the second update on, a worker that kills real jobs, a user waiting 180 minutes) — not something that could bite after a future change.
- **On a re-review round the bar is higher than on the first pass.** The author has already responded, the PR is close to approval, and another round costs more than a marginal finding is worth. Post only what would genuinely hold up the merge; note everything else in the file and let it go. Say so explicitly in the status block ("geprüft, nicht postenswert") so it is clear the point was considered rather than missed.
- **Apply a structural/architectural lens, not just a "is it mechanically detectable" lens** — this is where the highest-value findings hide:
  - Action/service classes that mix DB writes with notifications/dispatch → check transaction boundaries, ordering of irreversible side effects (e.g. broadcasts/webhooks before commit), partial-write / orphan-record safety, and whether async work belongs in the scheduler rather than dispatched inline.
  - New DB columns holding an external-system reference → check whether the name signals that, vs. looking like a local FK.
  - Route names ↔ permission keys ↔ URL paths → check they stay consistent with each other and with sibling endpoints.
  - **Dead / unnecessary / speculative code** → does every new class, method, branch, config key, or middleware actually earn its place? The sharpest smell is code that is **inert as shipped** — effort with zero effect: config that makes its own consumer a no-op (e.g. an empty allowlist that turns a middleware into a pass-through, like `AllowIps` with empty `allowed_ips` and no env wiring), branches unreachable on any real call path, dead endpoints. Flag those. **But do not confuse "no caller yet" with "unnecessary":** a class that faithfully models a first-class concept of the external system/API being integrated (e.g. a Prometheus metric type like `Counter`/`Histogram`) is completing a domain model, not speculating — it's legitimate even with no producer yet, especially if cheap and covered by a contract test. Reserve the YAGNI flag for *internal* abstractions with no consumer *and* no domain justification. Always trace actual callers/reachability before flagging — confirm, don't assume — and separate "carried over verbatim from the replaced code" (note it, lower severity) from "newly introduced and already unused".
- **Before proposing to remove anything as "unused", cross-check it against every other finding in the same review.** An unused parameter, field, enum case or config key is very often the half-built answer to a gap you flagged somewhere else — removing it would take the review in exactly the wrong direction. Collect the "X is unused, can it go?" candidates **last**, and for each one ask: does any other finding describe the hole this would fill? If yes, invert it — the finding is "X exists but is not wired up yet", not "X can go". Real case (RTM-3526): the review proposed deleting `$targetFirmwareVersion` because no driver read it, while a second finding said the Secunet driver can never detect a failed update — and the target firmware version is precisely what that detection needs. Both were posted and the first comment had to be walked back.
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

### 5a. Start with the status block — and no overall comment

Begin the file with a short **status block** for yourself (what the change does; DoD met / gaps; PHPStan/Pint/test results) — this stays in the file.

**Do not write a paste-ready overall/top-level PR comment.** No `## Gesamt-Kommentar` section, no summary paragraph in the reviewer's voice, no numbered list of "biggest impressions". The deliverable is the per-finding comments only; the user writes the overall comment themselves if they want one.

That means the **cross-cutting themes still have to land somewhere concrete** — never drop them, and never let them become a summary block by another name:

- Anchor an architectural/structural point to the **one place in the diff where it is most visible** (the action that owns the transaction, the controller line that authorizes, the model that duplicates a rule) and write it as a normal finding there.
- If it genuinely has no anchor in the diff, it goes under `## Ohne Diff-Bezug` (see 5b), with the comment text naming where it belongs.
- Cross-reference related findings by linking to the first one instead of restating the theme in each.

### 5b. Order the findings by the Gitea diff — NEVER by severity

The file is a **walking aid for the Gitea diff view**: the user opens the PR, goes file by file, and pastes the comments as they pass each spot. So the order of the findings must match the order Gitea shows the files in — anything else forces them to jump back and forth and makes the file unusable.

- **Primary sort: the file order returned by `list_gitea_pull_request_files`.** That is exactly the order the Gitea diff view renders (path-alphabetical). Do not re-sort it, do not put "important" files first. In ticket/commit mode, use the file order of `git diff --stat <base>..<head>` instead.
- **Secondary sort: ascending line number** within one file.
- **Group findings under one `## \`path/to/File.php\`` heading per file**, in that order, with the findings as `###` sections underneath. One heading per file even when it holds only one finding — the user scrolls to the heading that matches the file they have open.
- **Severity is triage metadata, not a sort key.** It stays in the finding title (`### [major] …`) so the user can judge what matters, but it never influences position. A `nit` in the first file comes before a `major` in the fifth.
- **Findings with no anchor in the diff go last**, under a final `## Ohne Diff-Bezug` heading — e.g. a point about a file the PR does not touch (a sibling endpoint that *should* have been changed too), or a repo-wide observation. Gitea cannot attach a line comment to an unchanged file, so say in the comment text itself where it belongs (usually: attach it to the closest changed line and name the other file, or post it as a standalone remark). Never bury such a finding in the middle of the file order — it breaks the walk.
- **Right after the status block, add a `## Reihenfolge (Gitea-Diff)` index**: one line per file in diff order, each listing its findings as `F<n> [severity] Kurztitel`. This is the checklist the user ticks off while walking the diff. Files without findings are omitted.
- **Give every finding a stable id `F<n>`, numbered in diff order** — F1 is the first finding in the first file, and the count runs on through the `## Ohne Diff-Bezug` section. The id goes into the finding title (`### F3 · [minor] …`) and in front of its entry in the `Reihenfolge` index. It exists **only for talking about the review** — so the user can say "F3 ist erledigt, F5 poste ich nicht" instead of quoting the title — and must **never** appear in a pasted Gitea comment. Assign the numbers once and do not renumber within a review file; if a finding is dropped later, its number stays retired. Whenever a status table, a cross-reference or a later section points back at a finding, use the id.

Example skeleton:

```
## Reihenfolge (Gitea-Diff)

1. `app/Http/Controllers/.../FooController.php` — F1 [nit] Meldung im Konjunktiv
2. `app/Service/Foo/Actions/BarAction.php` — F2 [major] Kein Broadcast · F3 [minor] Falsche Begründung
3. `tests/Feature/Service/Foo/BazTest.php` — F4 [minor] Test im falschen Verzeichnis
   → Ohne Diff-Bezug: F5 [minor] Schwester-Endpoint ohne Guard

## `app/Http/Controllers/.../FooController.php`

### F1 · [nit] Meldung im Konjunktiv
…
```

### 5c. Then one section per finding, in this exact shape

```
### F<n> · [blocker|major|minor|nit] Kurzer Titel

📍 **`path/to/File.php:42`** · `methodOrSymbolName()` <— zur Orientierung, wo der Kommentar hingehört

(Sowohl die `F<n>`-ID als auch das Severity-Tag bleiben NUR hier im Titel — als Referenz bzw.
Bewertung/Triage für uns. Beides kommt NICHT in den Gitea-Kommentar.)

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

- **Location line (📍)** — put it on its **own line directly under the title**, not buried in the title. Bold `path:line` plus the enclosing method/class/symbol so the reviewer can find the exact spot to attach the comment in Gitea at a glance. Every finding gets one — also under a `## <path>` heading, since the exact line is what the user needs there (the heading only gets them to the right file).
- **Anchor a readability finding where the reader stumbles, not where the symbol is defined.** "I had to read this twice" is a statement about the *call site* — the method signature, the parameter name, the comparison you tripped over — so that is where the comment belongs, and the fix is almost always to rename the method or the parameter. Anchoring it at the definition of the constant or config key the code happens to read moves the comment away from the confusing line and proposes the wrong fix. Real case (RTM-3526): the review flagged the config keys `firmware_update_blackout_before_minutes` / `..._after_minutes` in `config/rtm.php`; the reviewer instead commented on the rule's private methods and their `$executeAt` parameter — and that is what got renamed.
- **Gitea-Kommentar** — the copy-paste deliverable, and it must read like *this reviewer's* voice, which is **shorter than you think**: usually **one or two sentences**, often just a genuine question or one concrete rename/alternative. Look at the calibration examples below and match that length and tone. Hedge, name existing code/solutions by their real path (e.g. `App\Service\Firmware\Sorts\VersionSort`), prefix trivia with `nit:`, mark optional/out-of-scope explicitly ("kein Muss"), and suggest a follow-up ticket where it fits. Cross-reference duplicates with a link. Never a `[major]`/`[minor]` tag in the comment.
- **Deeper analysis → attributed optional block.** Do **not** inflate the reviewer's own short comment with a wall of technical reasoning. Keep the human comment tight, then, if the point rests on deeper analysis, append it as a clearly **AI-attributed, explicitly optional** block ("Laut KI …", "Die KI plädiert hier relativ stark für ein Histogram 😄", "Muss man nicht aufnehmen, fands nur spannend:"). This two-tier split — short human ask + attributed optional deep-dive — is exactly how this reviewer posts.
- **Kontext** — for the user's understanding, not for posting: root cause, concrete impact (bug, security, performance, maintainability), recommended fix, grounded in `file:line` and any relevant Confluence doc. Keep it as short as the point allows.

The severity tag (`[blocker|major|minor|nit]`) stays in the finding **title** as the rating — only keep it out of the pasted comment.

### 5d. Voice calibration — real examples of this reviewer's comments

Match this register and length. These are the target; the wall-of-text paragraph is the anti-pattern.

- Middleware/config no-op → *"Brauchen wir diese Middleware und den dazugehörigen Config Eintrag? In der Config ist es eine statische leere Liste, das hat also keinen Effekt."*
- Duplicated construction → *"Die `CollectorRegistry` wird im `MessageBrokerServiceProvider` quasi identisch nochmal gebaut. Vielleicht wäre es besser, diese nur einmal als Singleton zu definieren anstatt sie hier an die ServiceProvider-Instanz zu hängen."*
- Naming + concrete alternative → *"Wäre als Name nicht etwas wie `konnektor_registration_card_missing` besser? Hier werden ja nicht mehr unterschiedliche Status über das Label abgebildet … Das `status` Label wäre dann auch obsolet."*
- Test placement question → *"Sind die Tests bewusst in dem `Unit` Verzeichnis gelandet? Ich glaube die Trennung wurde bisher nicht absolut konsistent durchgezogen …"*
- nit → *"nit: Hier wäre eventuell auch ein Name mit `_count` passender, oder?"*
- Deep AI suggestion (attributed, optional) → *"Die KI plädiert hier relativ stark für ein Histogram 😄:"* followed by the detailed block.

End with an **Offene Fragen** section for anything you couldn't confirm — after the per-file sections and the `## Ohne Diff-Bezug` section, at the very bottom of the file.

So the final file layout is: status block → `## Reihenfolge (Gitea-Diff)` → one `## <path>` section per changed file in diff order → `## Ohne Diff-Bezug` → `## Offene Fragen`.

## Stay in scope

This is analysis, not a fix. Don't edit source files and don't post anything to Gitea yourself — the German comments are for the user to paste. Only write the review file under `~/code/knowledge/work-log/`.
