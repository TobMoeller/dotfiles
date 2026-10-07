---
name: review
model: opus
effort: high
description: Review a Gitea PR or the commits for a ticket — gathering context from Gitea, Jira (and Confluence when needed), fanning out three blind reviewer subagents and a step-verifier Über-Review that merges and refutes their findings — and write findings to the central work-log store (~/code/knowledge/work-log/), each with a ready-to-paste short, sober German PR comment (voice per the comment skill) plus a detailed rationale. Use when the user asks to review a PR, a ticket's changes, or commits (e.g. "review PR 1818", "review RTM-3122", "review the changes for RTM-3444"). Reviews backend (PHP) code by default; only inspects frontend code when the user explicitly asks for a frontend or full-stack review.
allowed-tools: Agent Read Grep Glob Bash(git log:*) Bash(git diff:*) Bash(git range-diff:*) Bash(git show:*) Bash(git branch:*) Bash(git rev-parse:*) Bash(mkdir:*) Bash(vendor/bin/phpunit:*) Bash(vendor/bin/phpstan:*) Bash(vendor/bin/pint:*) mcp__devtools-mcp__get_gitea_pull_request mcp__devtools-mcp__get_gitea_pull_request_diff mcp__devtools-mcp__list_gitea_pull_request_files mcp__devtools-mcp__list_gitea_pull_request_commits mcp__devtools-mcp__list_gitea_pull_request_comments mcp__devtools-mcp__list_gitea_pull_request_checks mcp__devtools-mcp__search_gitea_pull_requests mcp__devtools-mcp__read_jira_issue mcp__devtools-mcp__search_jira mcp__devtools-mcp__search_confluence mcp__devtools-mcp__read_confluence_page mcp__devtools-mcp__get_confluence_page_by_title
---

# Code review (red / work)

Produce a codebase-grounded review written to the central `work-log` store, where every finding ships with a short, sober German comment to paste into the Gitea PR (written per the `/comment` skill in `paste` mode) and a detailed rationale.

## 1. Determine what to review

Two input modes — pick based on what the user gave you:

- **A Gitea PR** (a PR number or URL): fetch it with the Gitea MCP.
  - `get_gitea_pull_request` for metadata (title, description, branch, linked ticket)
  - `get_gitea_pull_request_diff` for the diff, `list_gitea_pull_request_files` / `list_gitea_pull_request_commits` for scope
  - `list_gitea_pull_request_comments` so you don't repeat points already raised
  - `list_gitea_pull_request_checks` (`state: all`) for the CI results — see step 4
- **A ticket number** (e.g. `RTM-1234`): a review always runs against a PR. Look for the open PR first (`search_gitea_pull_requests` by ticket number or branch) and, if there is one, continue in PR mode.
  - **No open PR → stop before the fan-out and ask the user how to proceed** (AskUserQuestion, or in the result when there is nobody to ask). Say what you found (`git log --all --grep=RTM-1234 --oneline`: commits, branch) and offer the options: wait for the PR, review the commits locally anyway, or drop it. No automatic local fallback.
  - Only when the user chooses the local review: review the combined change (`git show <commit>` for one, `git diff <base>..<head>` for a range), confirm the range first if the ticket maps to several commits or a branch, and run the local checks from step 4.

If it's ambiguous which mode applies (or which PR/commits), **ask** before proceeding. Derive the ticket number from the PR title/branch when it isn't given explicitly.

### Re-Review — check the delta, not the PR again

Trigger: this session has already reviewed the ticket/PR (`review.md` exists in its work-log folder) and gets `/review PR <n>` again, or the prompt says „Re-Review". Then do not start over — you know the findings, their Beleg and the code paths:

- **Start from `review.md`:** the reviewed head SHA, the findings `F<n>` with their evidence, the open questions.
- **Determine the delta since the reviewed head.** Fetch if the new head is missing locally (one line to the user, as in step 3). `git range-diff <base>..<alt-head> <base>..<neu-head>` tells a rebase/force-push (every commit `=`, only SHAs new) from real changes; for a linear push `git diff <alt-head> <neu-head>` is the delta. Note what the base brought in when it moved.
- **Read the CI of the new head** (step 4, head match as usual).
- **Per old finding record `behoben / offen / neu bewertet`** — verified against the code at the new head, not against the commit message or the author's reply. Look for new findings **only in the delta**; the unchanged code was reviewed.
- **Small or contentless delta** (a pure rebase, a few lines answering the comments): no reviewer fan-out and no Über-Review — check it yourself and say so in the status block. The fan-out stays for a **large new delta** only; rule of thumb: more than about 200 changed lines of new backend code, judged, not counted.
- Steps 2 and 4 apply as before; the output is `rereview.md` next to `review.md` (step 5e). No comments on Gitea, as always.

## 2. Gather the ticket context

- Read the linked ticket via the Jira MCP (`read_jira_issue`) — pull the description and the **Definition of Done / acceptance criteria**.
- **A PR is up for review only once its author assigned the Jira ticket to the user** — a Gitea review request alone does not make it ready. If the ticket is not assigned to the user, say so in one line and ask whether to review anyway.
- **If Jira is unreachable, make one attempt then stop** and ask the user to paste the ticket content. Do not retry in a loop.
- Consult **Confluence only when needed** — i.e. the change touches a documented design/convention you must check it against (`search_confluence`, then `read_confluence_page` / `get_confluence_page_by_title`). Skip it otherwise.

## 3. Review against the real code — three reviewers, one Über-Review

Same pattern as `/pre-review` and the review phase of `/work`: three blind reviewers → one Über-Review that merges and refutes → the auditor only for a conflict nobody can settle. This context briefs the agents, collects their result blocks and writes the file.

- **Scope for the agents.** They recompute the diff with git themselves, so the PR head must exist locally: `git rev-parse --verify <head>` (e.g. `origin/<head-branch>`). If it does not, ask the user to fetch it in one line — never paste the Gitea diff into the briefs. PR mode: `git diff origin/<base-branch>...<head>` (three dots, the range Gitea shows; its file list must match `list_gitea_pull_request_files`). Local review without a PR (user's choice in step 1): the range confirmed there. When the checkout is not on the head, the agents read files as `git show <head>:<path>`.
- **Fan out:** spawn **three `reviewer` subagents in one message** (`subagent_type: reviewer`) with identical briefs, blind to each other, no split focus — as in `/pre-review`. Brief only what they cannot know: the scope commands and the head ref, the ticket summary + DoD/acceptance criteria with the instruction to flag gaps, „backend only" unless the user asked for frontend, and the lens below (`~/.claude/skills/review/SKILL.md`, section „The review lens"), in PR mode the coverage warnings of changed classes from step 4 (verbatim, as hints, not findings) and the line „Keine Tests, PHPStan oder Pint lokal ausführen, die CI hat sie gelaufen". Not the existing Gitea comments; those are filtered when writing.
- **Über-Review:** one `step-verifier` in **Modus: widerlegen** gets the three result blocks verbatim, labelled R1–R3, plus scope, head ref, acceptance criteria and — in PR mode — the same coverage hints and no-local-checks line. It merges them (same spot + same claim → one finding, count `n/3`, never drops a single-reviewer finding), tries to refute each against the code at the head, and sets the severity of every survivor. More than ~20 raw entries → merge yourself first and split the merged list over up to 5 step-verifiers, as in `/work`.
- **Auditor only for a real conflict:** a finding at least two reviewers raised independently that the Über-Review refutes goes to the `auditor` with both positions verbatim (the reviewers' Beleg vs. the refutation's Beleg). `A`/`B`/`anders` settles it; `Tobias` → `## Offene Fragen` with the auditor's question and recommendation. At most two auditor calls per review; further conflicts go to `## Offene Fragen` with both positions.
- **Re-review round (`rereview.md`):** only for a large new delta (rule of thumb in step 1): one `reviewer` on the delta since the last review, then the same Über-Review — like `nacharbeiten` in `/work`. Three only when the user asks. A small delta or a pure rebase gets no fan-out; this context checks it itself.

### The review lens

The reviewers apply it when finding, the Über-Review when rating, this context when writing.

- **Scope: backend only by default.** Review backend code (PHP — `app/`, `routes/`, `database/`, `config/`, `tests/`, …). Do **not** raise findings on frontend code (`resources/client/js/**`, `.vue`, `.ts`) unless the user explicitly asks for a frontend or full-stack review. When you skip frontend changes, note it in one line in the summary so it's clear the FE side was out of scope and can be requested separately.
- Verify every finding against the actual codebase — open the surrounding code, follow the call paths, confirm behavior. **Never speculate.** If you cannot confirm something (failure handling, a deploy path, reachability of an edge case), say so explicitly rather than asserting it.
- Check the change against the ticket's DoD and call out any gaps.
- **Record every finding the Über-Review confirmed.** Whether it gets a paste-ready comment is decided per finding afterwards (Kontext only, or „geprüft, nicht postenswert"), not by leaving it out — a finding you drop here is one Tobias never gets to weigh. Style nits that Pint or PHPStan would catch are the only exception.
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

## 4. Tests and static checks — read the CI, don't rerun it

### PR mode: Gitea CI

Gitea already runs tests, PHPStan, Pint and coverage on every PR push. **Do not run phpunit, PHPStan or Pint locally for a PR** — not in this context, and tell the agents the same. Read the CI result instead:

- `list_gitea_pull_request_checks` (owner, repo, index, `state: all`). Do this before fanning out (step 3), the coverage hints go into the briefs.
- **Head match:** every check carries `commitSha`/`updatedAt`. Compare against the PR head SHA (`get_gitea_pull_request`, and `git rev-parse <head>` for the local ref the agents read). Checks on an older SHA do not count for this head.
- **No checks, or only checks for an older SHA** (CI not run yet, still running, or pushed since): note it in the status block (`CI: keine Checks für <sha>` / `CI: Checks gehören zu <alt-sha>, Head ist <sha>`) and carry on with the review. **No local fallback** — the user re-runs the review once CI is through, or asks for local checks explicitly.
- **`Approvals (x/y)`** is a review gate, not CI. Leave it out of the CI verdict.
- **A red check on the head** (failing tests, PHPStan or Pint errors) is a finding only when it points into the changed code — then include it as a finding at that spot (`**Gefunden:** CI`, no Über-Review needed). A red check outside the diff goes into the status block only.

**Coverage per changed class is input, not a finding.** CI posts a `warning` per class below the threshold, with the missing lines (e.g. `Coverage - App\Service\…\FinalizeCardTerminalFirmwareUpdate 90.72% - Missing: L148-156`). Collect those whose class file the PR changes and hand them to the reviewers and to the Über-Review verbatim (class, percentage, missing lines). The agents check whether the missing lines fall into the diff and cover changed behaviour — if so, that can become a test-gap finding with a concrete scenario, raised and refuted like any other. A coverage warning on its own never becomes a finding, and warnings for classes the PR does not touch are dropped.

### Local review without a PR (only on the user's explicit choice)

There is no CI to read. Only because the user chose the local review in step 1, verify locally, but **never run the full test suite** — only the tests relevant to the change, with the phpunit executable directly (not `php artisan test`):

- `vendor/bin/phpunit path/to/RelevantTest.php` or `vendor/bin/phpunit --filter <TestName>` — the test files covering the changed classes
- **PHPStan:** `vendor/bin/phpstan analyse` and **Pint:** `vendor/bin/pint --test` — fast, run across the whole project

A failing test, a PHPStan error or a Pint violation in the changed code is a finding (`**Gefunden:** Check`, no Über-Review needed).

## 5. Write the review

Write to the central work-log store, **not** into the checkout (a `.reviews/` inside a worktree is destroyed by `wt rm`). The target is `~/code/knowledge/work-log/<repo>/<TICKET>/review.md` — one folder per ticket, co-located with its spec if one exists. Use `rereview.md` in the same folder for a follow-up pass, and a slug folder (e.g. `PR-<id>/review.md`) when there's no ticket. `<repo>` is the main repository name — stable across the main checkout and all its worktrees. Resolve and create it with:

```bash
repo=$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")
mkdir -p ~/code/knowledge/work-log/"$repo"/<TICKET>
```

Then write to `~/code/knowledge/work-log/$repo/<TICKET>/review.md`.

### 5a. Start with the status block — and no overall comment

Begin the file with a short **status block** for yourself (what the change does; DoD met / gaps; the CI result; one line „3 Reviewer · n Befunde roh · m nach Merge · k widerlegt · a Auditor") — this stays in the file.

The CI result is compact — one line for the green case, then only what is not green:

```
**CI** (Head `<sha kurz>`, Checks vom <updatedAt> · passen zum Head | gehören zu `<alt-sha>` | keine Checks):
Tests ✓ 7937 · PHPStan ✓ · Pint ✓ · Coverage gesamt <x %>
- <nicht grüner Check einzeln: Name · Status · Beschreibung>
- Coverage-Warnungen geänderter Klassen: <Klasse> <x %> fehlt L<a-b> (→ F<n> | im Diff nicht relevant)
```

`Approvals` stays out of it. In a local review without a PR the line reads `Lokal (ohne PR, auf Wunsch): Tests <x/y> · PHPStan · Pint` instead.

**Do not write a paste-ready overall/top-level PR comment.** No `## Gesamt-Kommentar` section, no summary paragraph in the reviewer's voice, no numbered list of "biggest impressions". The deliverable is the per-finding comments only; the user writes the overall comment themselves if they want one.

That means the **cross-cutting themes still have to land somewhere concrete** — never drop them, and never let them become a summary block by another name:

- Anchor an architectural/structural point to the **one place in the diff where it is most visible** (the action that owns the transaction, the controller line that authorizes, the model that duplicates a rule) and write it as a normal finding there.
- If it genuinely has no anchor in the diff, it goes under `## Ohne Diff-Bezug` (see 5b), with the comment text naming where it belongs.
- Cross-reference related findings by linking to the first one instead of restating the theme in each.

### 5b. Order the findings by the Gitea diff — NEVER by severity

The file is a **walking aid for the Gitea diff view**: the user opens the PR, goes file by file, and pastes the comments as they pass each spot. So the order of the findings must match the order Gitea shows the files in — anything else forces them to jump back and forth and makes the file unusable.

- **Primary sort: the file order returned by `list_gitea_pull_request_files`.** That is exactly the order the Gitea diff view renders (path-alphabetical). Do not re-sort it, do not put "important" files first. In a local review without a PR, use the file order of `git diff --stat <base>..<head>` instead.
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

**Gefunden:** 2/3 · **Über-Review:** bestätigt, <Beleg in einem Satz> <— nach Auditor: „widerlegt, Auditor: bestätigt, …"

(Sowohl die `F<n>`-ID als auch das Severity-Tag bleiben NUR hier im Titel — als Referenz bzw.
Bewertung/Triage für uns. Beides kommt NICHT in den Gitea-Kommentar.)

**Gitea-Kommentar (zum Kopieren):**
> <Formuliert nach dem `/comment`-Skill im Modus `paste`: 1–3 Sätze, hart bei max. 4. Das
> Problem in einem Satz, die Lösung nur, wenn sie nicht auf der Hand liegt. Fragen als Fragen,
> ohne Hedge. Trivia mit "nit:". Optionales in einem Satz als Fakt ("Kein Muss."). Dubletten per
> Link auf den ersten Kommentar statt Wiederholung. KEIN Marker, KEINE [major]/[minor]-Klammern,
> KEINE F<n>-ID.>

<NUR wenn der Punkt ohne eine tiefere Analyse (Cardinality, PromQL, Trade-offs …) nicht steht:
NICHT in den kurzen Kommentar pressen, sondern als klar ALS KI ausgewiesenen, ausdrücklich
optionalen Block anhängen:>

> Laut KI, muss nicht übernommen werden:
> <hier der Detailblock — gern mit Code/PromQL-Beispiel>

**Kontext (für dich, nicht zum Posten):**
<knapp: Ursache, konkrete Auswirkung, empfohlener Fix — mit file:line und ggf. Confluence-Doku;
nur so lang wie nötig>
```

Guidance for the parts:

- **Location line (📍)** — put it on its **own line directly under the title**, not buried in the title. Bold `path:line` plus the enclosing method/class/symbol so the reviewer can find the exact spot to attach the comment in Gitea at a glance. Every finding gets one — also under a `## <path>` heading, since the exact line is what the user needs there (the heading only gets them to the right file).
- **Anchor a readability finding where the reader stumbles, not where the symbol is defined.** "I had to read this twice" is a statement about the *call site* — the method signature, the parameter name, the comparison you tripped over — so that is where the comment belongs, and the fix is almost always to rename the method or the parameter. Anchoring it at the definition of the constant or config key the code happens to read moves the comment away from the confusing line and proposes the wrong fix. Real case (RTM-3526): the review flagged the config keys `firmware_update_blackout_before_minutes` / `..._after_minutes` in `config/rtm.php`; the reviewer instead commented on the rule's private methods and their `$executeAt` parameter — and that is what got renamed.
- **Gitea-Kommentar** — the copy-paste deliverable. **Load the `/comment` skill and write it in `paste` mode.** Its voice and hard rules apply in full: sober and direct, **one to three sentences**, the consequence in the first sentence, the fix only when it is not obvious, questions as plain questions without hedge words, no emoji, no dashes or colon lead-ins, at most two identifiers (one to locate, one for the replacement, using the real name of existing code such as `App\Service\Firmware\Sorts\VersionSort`). Prefix trivia with `nit:`, state optional/out-of-scope as a fact in one short sentence ("Kein Muss.", "Kann ein eigenes Ticket werden."). Cross-reference duplicates with a link. Never a `[major]`/`[minor]` tag or `F<n>` id in the comment, no marker in `paste` mode.
- **Deeper analysis → `Kontext` first, attributed block second.** Do **not** inflate the short comment with technical reasoning. The analysis belongs in the `Kontext` block below. Only when the point cannot stand without it, append it as a clearly **AI-attributed, explicitly optional** block ("Laut KI, muss nicht übernommen werden:") after the short comment.
- **Kontext** — for the user's understanding, not for posting: root cause, concrete impact (bug, security, performance, maintainability), recommended fix, grounded in `file:line` and any relevant Confluence doc. Keep it as short as the point allows.

The severity tag (`[blocker|major|minor|nit]`) stays in the finding **title** as the rating — only keep it out of the pasted comment. It is the Über-Review's severity (or the auditor's), not a reviewer's.

#### Refuted findings

Everything the Über-Review refuted (and the auditor did not revive) goes under `## Widerlegt`, one line each: `` `path:line` · Behauptung · n/3 · Beleg ``. No `F<n>` id, no comment, no Kontext block — it is only there so Tobias sees the point was raised and why it fell.

### 5d. Voice calibration

Match this register and length. The sober line is the target; the hedged, chatty paragraph is the anti-pattern (the `/comment` skill has more before/after pairs).

- Middleware/config no-op → *"Die Middleware hat keinen Effekt, die Liste in der Config ist statisch leer. Brauchen wir sie?"*
- Duplicated construction → *"Die CollectorRegistry wird im MessageBrokerServiceProvider ein zweites Mal gebaut. Einmal als Singleton registrieren."*
- Naming + concrete alternative → *"Das Label status bildet nur noch einen Zustand ab. Als Name passt `konnektor_registration_card_missing` ohne Label."*
- Test placement → *"Die Tests unter Unit nutzen die Datenbank. Nach Feature verschieben."* (or, when genuinely unsure: *"Sind die Tests absichtlich unter Unit? Sie nutzen die Datenbank."*)
- nit → *"nit: das ist ein Zähler, also Suffix _count."*
- Deep AI suggestion (attributed, optional) → *"Histogram statt Gauge, dann lässt sich die Verteilung abfragen."* followed by *"Laut KI, muss nicht übernommen werden:"* and the detailed block.
- Anti-pattern → *"Brauchen wir diese Middleware und den dazugehörigen Config Eintrag? In der Config ist es eine statische leere Liste, das hat also keinen Effekt."* and *"Ich glaube die Trennung wurde bisher nicht absolut konsistent durchgezogen …"* — hedged, indirect, twice as long as needed.

End with an **Offene Fragen** section for anything you couldn't confirm (including auditor rulings that went to Tobias) — after the per-file sections, `## Ohne Diff-Bezug` and `## Widerlegt`, at the very bottom of the file.

So the final file layout is: status block → `## Reihenfolge (Gitea-Diff)` → one `## <path>` section per changed file in diff order → `## Ohne Diff-Bezug` → `## Widerlegt` → `## Offene Fragen`.

### 5e. `rereview.md` — the re-review file

Same folder as `review.md` (a second re-review overwrites it; note the round in the title), same register, built around the delta:

- `# Re-Review PR <n> · <TICKET> · Push vom <Datum Zeit>`
- `## Status (für dich)`: PR link, new head (old head in brackets), base and whether it moved; **what the push is** (pure rebase/force-push, or new commits with one line each, PR text changed?); **Durchlauf** (checked yourself, or one reviewer + Über-Review, and why); ticket assignment/status; then the CI block from 5a for the new head, with „neu gegenüber dem Review" called out.
- `## Alte Befunde`: one line per `F<n>` from `review.md`, ids kept: `F<n> · behoben | offen | neu bewertet · <Beleg in einem Satz>`. An open one keeps its comment in `review.md` (do not repeat it); a re-rated one gets its new severity and the reason.
- **New findings** as in 5b/5c: `## Reihenfolge (Gitea-Diff)` plus one `## <path>` section per file, numbered on from the last `F<n>` of `review.md` — „Keine neuen Befunde" when there are none. Then `## Widerlegt` (new ones only) and `## Offene Fragen` (unchanged ones named as unchanged, settled ones dropped).

## Stay in scope

This is analysis, not a fix. Don't edit source files and don't post anything to Gitea yourself — the German comments are for the user to paste. Only write the review file under `~/code/knowledge/work-log/`.
