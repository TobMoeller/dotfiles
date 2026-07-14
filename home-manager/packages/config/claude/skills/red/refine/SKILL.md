---
name: refine
description: Prepare for sprint refinement — pull a KW sprint's tickets from Jira (in Backlog/Rank order) and write a short German pre-read: per ticket, one plain-language explanation of what it wants and whether it's implementable, any genuinely real concerns (only when the ticket is under-defined or problematic — never manufactured), and a single code-grounded story-point estimate calibrated to RTM history. One subagent per ticket → independent results. Then walk the user through it interactively (accept/retune SP, ask a question, postpone, pause), recording an agreed SP per ticket as at-a-glance bullets for the team meeting. Writes a single pre-read to the work-log store (~/code/knowledge/work-log/refinement/). Read-only against Jira; never writes estimates back. Use when the user wants to prep refinement or estimate a sprint (e.g. "refine the next sprint", "estimate KW 30-32", "prep tomorrow's refinement").
allowed-tools: Read Grep Glob Bash(git log:*) Bash(git diff:*) Bash(git show:*) Bash(git branch:*) Bash(git rev-parse:*) Bash(git fetch:*) Bash(git worktree:*) Bash(git reset:*) Bash(mkdir:*) Write Edit Agent mcp__devtools-mcp__read_jira_issue mcp__devtools-mcp__search_jira mcp__devtools-mcp__search_confluence mcp__devtools-mcp__read_confluence_page mcp__devtools-mcp__get_confluence_page_by_title
---

# Sprint refinement estimation (red / work)

Turn a sprint's Jira tickets into a **short refinement pre-read**, then **walk the user through it interactively** to lock in a story-point number per ticket before the team meeting.

The purpose is to check, ahead of refinement, that **each ticket is well-defined enough to implement**, and to **pre-agree an SP estimate** — so the meeting is faster and the user only has to read out a number. It is **not** to manufacture discussion. For each ticket the pre-read gives exactly three things:

1. **What the ticket wants, and whether we could implement it** — one clear, plain-language explanation (names the RTM subsystems/concepts involved), enough that the reader understands the ticket and can judge "yes, we could build this."
2. **Concerns — only if real.** Surface something *only* when the ticket is genuinely under-defined, contradictory, blocked, or built on a false premise — i.e. something that would actually stall implementation or the estimate. If the ticket is clear, say nothing here. **Do not invent a question per ticket to fill the meeting** — that is explicitly not the job.
3. **SP estimate** — a single code-grounded story-point number (+ confidence + one-line rationale), calibrated to RTM history.

**Keep it tight.** One explanation per ticket, no repetition across sections, no summary tables restating the same thing. The user reads this front-to-back, so every line must earn its place.

After writing it, run the **interactive walkthrough** (step 6): go ticket by ticket, let the user accept/retune the SP, ask a question, postpone, or pause — and record each decision as a one-line bullet in a **results** section, so they walk into the team meeting with a ready SP per ticket.

The output is a **pre-read for a human**: draft numbers to react to, never a decision made for the team.

## Stay in scope

- **Read-only against Jira.** Read tickets; **never** write story points or any field back to Jira. There is no capture-back step by design.
- **Do not change project source files.** Reading and tracing code is expected; editing it is not.
- **Write only under `~/code/knowledge/work-log/`.** Don't commit the store unless the user asks.

## The estimate field (RTM Jira custom field)

The RTM team uses a **single Story Points field for total effort** — dev, QA, and everything else folded into one number. They do **not** split dev vs QA. When reading an issue, the estimate lives in:

- `customfield_10005` — **Story Points**. The single, authoritative estimate — this is the field that holds values. The `estimate` field mirrors it wherever both are set — read whichever is present.
- `customfield_10100` — Initial Story Points (early guess; fallback signal only).
- Other fields exist in the JSON (`customfield_10600` "Story Points QA", `customfield_12000` "QA SP used", `customfield_11700`) but the team does **not** use them — ignore them. They were empty across the whole calibration sample.

Produce **one combined Story Points estimate per ticket** from the scale below — never a separate dev vs QA number, even for a "QA: Volltest …" story (that gets a single estimate like any other ticket). If `customfield_10005` is already set, flag `ALREADY-ESTIMATED` and verify rather than re-invent.

## 0. Prepare a clean code baseline (origin/develop) — do this first

Estimates must reflect the code the sprint will actually build on, not whatever branch/WIP the user is currently on. So all code tracing happens against a freshly-fetched **`origin/develop`**, in a dedicated **read-only, docker-less worktree** (estimation only *reads* code — it never runs the app, DB, migrations, or tests, so no `.env` / compose / `composer` / `npm` is needed).

**This is not routed through the `wt` script** (that builds a full dockerized dev env). Manage the snapshot worktree directly:

```bash
main=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")   # main checkout (stable from any worktree)
repo=$(basename "$main")
wt_root="${WT_ROOT:-${WT_CODE_DIR:-$HOME/code}/worktrees}"
ro="$wt_root/$repo/develop-refine-ro"                                        # persistent read-only snapshot

git -C "$main" fetch origin develop                                          # refresh remote-tracking ref
if [ -d "$ro" ]; then
  git -C "$ro" reset --hard origin/develop                                   # refresh in place
else
  mkdir -p "$wt_root/$repo"
  git -C "$main" worktree add --detach "$ro" origin/develop                  # first-time create (detached, no branch)
fi
```

**Hard-fail policy:** if the fetch or the worktree create/reset fails (offline, SSH/gitea auth, git error), **abort the run** and tell the user — do **not** fall back to estimating against a possibly-stale tree. Report the git error so they can fix auth/network and re-run.

All subsequent code tracing (step 4) reads under **`$ro`**. Caveats to keep in mind:
- `$ro` has **no `vendor/` or `node_modules/`** — library *internals* aren't readable there. That's fine for estimation (our own app code is what matters); if an agent truly needs a library's source, it may read it from the user's `$main` checkout, noting the version may differ.
- `git fetch` uses the user's gitea SSH key; interactive runs are fine, a fully headless/cron run may stall on auth (this is part of why the policy is hard-fail).

## 1. Target the sprint

The RTM board is a **Kanban** board — `get_jira_sprint` does **not** work for it (returns "Sprints werden vom Board nicht unterstützt"). Sprints exist only as **named sprints** of the form `RTM <year> KW <ww>-<ww>` (e.g. `RTM 2026 KW 30-32`), each carrying its human date range in the sprint `goal` text.

- If the user names a sprint/KW, resolve it to the exact sprint name and confirm.
- If the user says "**next**" (or nothing), you cannot auto-pick it reliably — "next" lives in the KW label + goal dates, not in a queryable flag. Discover the candidates and **confirm with the user**:
  - Read one issue from `project = RTM AND sprint in futureSprints()` and inspect its `sprints` array to see the exact current sprint-name format (search results do **not** include the sprint name).
  - Cross-check the KW against today's date (a KW label starting after the current calendar week is "next").
- **Always confirm the exact sprint name with the user before estimating.**

## 2. Pull the tickets

```
sprint = "<exact sprint name>" ORDER BY Rank ASC
```
(maxResults 50). **Order by `Rank`** (`customfield_10012`) — this is the manual drag-and-drop order of the board's **Backlog** view, which is what the team sees and reads top-to-bottom in refinement. Matching it means the pre-read lines up with their screen (no "why is your order different?"). Do **not** order by `status`/`priority`: the RTM board has no per-ticket priority spread (almost everything is Medium), so a status sort produces an order nobody recognises. The Backlog view itself offers no sort control precisely because it *is* rank-ordered.

This gives you the ticket keys, types, and statuses. The per-ticket subagents (step 4) read each ticket in full — you don't need to read all descriptions yourself first. Note any ticket that already has `customfield_10005` set: it's "already estimated — verify, don't re-invent" (flag `ALREADY-ESTIMATED`).

Keep the pre-read (and the interactive walkthrough) in this same Rank order. The sprint's ticket set can change between pulls (tickets get added/removed during planning), so treat the count as of *this* pull and note if it differs from an earlier one.

## 3. Calibrate against RTM history (baked in)

Story points are **relative**, so size each ticket by "which past ticket does this most resemble?". These anchors are a fixed snapshot; refresh occasionally (see the end of this file). **Pass this whole section to every per-ticket subagent** so all estimates share one yardstick.

**Scale: `1, 2, 3, 5, 8, 13, 20, 40, 100`.** In practice almost all work lands at **2–3**, with **5** for substantial slices and **8** for large items. **13 and above are rare** — they usually signal the ticket should be **split** or needs a **spike**, but are legitimately used for genuinely large, indivisible work. Estimate **one combined Story Points value** per ticket — the team uses a single field for total effort (see "The estimate field" above); do not split dev vs QA.

_Snapshot: 2026-07-14, ~53 completed RTM tickets (Stories + Bugs), resolved 2025-07 … 2026-07. Observed range 1–8; the 13/20/40/100 tail exists but did not appear in the sample._

| SP | What it looks like | Anchor tickets |
| -- | ------------------ | -------------- |
| **1** | A tiny, self-contained change: one small scheduled task, or a one-line-ish FE fix. | RTM-3490 (scheduled cleanup of old `job_batches`); RTM-3423 (incident dialog objects not refreshed on template switch) |
| **2** | A small, well-understood fix or a thin slice leaning on existing code. Most bugs. | RTM-3349 (delete a pending notification draft — BE already existed); RTM-3105 (catch missing-SMC-B on backup, log); RTM-3402 (delete token on 401 + validate); RTM-3441 (dialog list formatting); RTM-3569 (doc emojis → FontAwesome icons) |
| **3** | One clear full-stack CRUD slice, one contained feature area, or a moderate bug. The workhorse size. | RTM-3346 (create individual incident, modal); RTM-3123 (claim reserved KIM address); RTM-3290 (catch Arvato 412 → friendly VZD message); RTM-3570 (split CA permission repos); RTM-3131 (restrict KIM card selection to connected call context) |
| **5** | A substantial full-stack feature slice (with permissions / states), multi-vendor or cross-cutting work, or a genuinely tricky prod bug. | RTM-3171 (customer dashboard, filterable, per-account); RTM-3417 (connector driver support for call-context CRUD); RTM-3474 (Prometheus counters for connector timeout/unreachable); RTM-3444 (route dedup so connections reuse broader route — prod bug); RTM-3299 (SSL problem on connector status retrieval) |
| **8** | A whole new mechanism/subsystem, a new API with sync/side effects, or a wide-blast-radius refactor. | RTM-3125 (KIM-reserve API + auto-create lead account); RTM-3502 (in-app contextual docs slide-over — whole mechanism + content); RTM-3348 (approval flow: status + Slack + editable draft); RTM-3226 (consolidate the two RTable components); RTM-3350 (Slack threaded notifications for approval lifecycle) |
| **13+** | Genuinely large / high-uncertainty work. **Rare.** Prefer `SHOULD-SPLIT` or `NEEDS-SPIKE` unless the work is truly indivisible. | (none in sample — use the 8-anchors ×1.5–2 as the mental step) |

**Calibration notes:**
- **Layer doesn't set the number — complexity/uncertainty does.** FE-only reached 8 (RTM-3226 RTable refactor); BE-only was 1 (RTM-3490 batch cleanup).
- **Bugs skew small**: almost all 2–3; only deep defects (SSL, deadlock, dialog error-state) reached 5–8.
- When a ticket feels bigger than the 8-anchors, that's the signal to flag `SHOULD-SPLIT` / `NEEDS-SPIKE`, not to reach for 13 by default.

## 4. Analyze each ticket — one independent subagent per ticket

Spawn **one `Agent` (subagent) per ticket**, in parallel, so results are independent (no anchoring between tickets). Give each subagent: the ticket key, the full **calibration section 3** (so every estimate uses the same scale), and the instructions below. Each subagent works **single-pass** — one estimate, no reconciliation round.

**Tool discipline — include this in every subagent prompt, verbatim and emphatic.** Estimation is pure reading, so the subagent must use the dedicated tools and almost never shell out:
- Use **Grep** for content search, **Glob** for finding files, **Read** for reading files. **Never** use their shell equivalents (`grep`/`rg`/`find`/`ls`/`cat`/`head`/`tail`/`sed`/`awk`) — the dedicated tools are faster and don't prompt.
- **Never chain or compose shell commands**: no `&&`, `;`, `|`, or `$(…)` substitution. One command per call. A composite/piped shell command is the **absolute, outermost exception** — permitted only when steps are genuinely interdependent *and* no dedicated tool fits, which for read-only code tracing under `$ro` is essentially never.
- Why it matters: every composite shell command forces a **manual approval prompt** on the user and stalls the parallel run. Treat "zero composite shell commands" as a hard requirement, not a preference. If a subagent thinks it needs one, that's a signal it should be a Grep/Glob/Read call instead.

Each subagent must:

1. **Read the ticket fully** (`read_jira_issue`): description, acceptance criteria/DoD, **comments**, and **linked issues / parent epic** (read the epic and relevant linked tickets too — RTM tickets often carry the real detail there).
2. **Ground in the code** — **under the clean `origin/develop` snapshot at `$ro` (section 0), not the user's working checkout.** Trace the real files the change touches — models, migrations, routes, controllers, actions/services, jobs/events, permissions, and the Vue components/stores/requests on the frontend. Cite `file:line` (paths relative to the repo root are fine). Give each subagent the absolute `$ro` path and tell it to point Grep/Glob at it.
3. **Research every uncertainty** before treating it as open. When the ticket is ambiguous, contradictory, or silent on something needed to implement it, try to answer it from — in order — the **code**, the **Jira** ticket/epic/comments, **Confluence** (`search_confluence` → `read_confluence_page` / `get_confluence_page_by_title`), and the **in-app docs** (`resources/docs/*.json` and `.claude/rules/documentation.md`). Watch specifically for **FE/BE divergence** and ticket-vs-code contradictions — they are common in RTM (e.g. a button enabled in the UI that the backend rejects). Record what you checked.
4. **Produce exactly these three things, written in German** (the pre-read is German; keep ticket keys, code identifiers, and flag labels as-is). Structured markdown, tight — no long code dumps, no file-path lists, no "resolved uncertainties" log, no layer/resembles tags as separate lines:
   - **What it wants & can we build it** — one plain-language paragraph (3–6 sentences), for someone still learning RTM. Say what the ticket asks for, **where in the system it lives** (name the RTM subsystems/concepts — e.g. "call contexts / Aufrufkontexte", "connector maintenance window", "in-app docs pipeline"), and end on the implementability read: is it clear enough to build, and roughly what it touches. This is the *one* explanation of the ticket — make it good; it replaces every other summary. For a badly-written ticket, this is where you decode it into something understandable.
   - **Open question** — *only a genuine one.* Return an open question **only** when something must be answered/decided before or during implementation, or when it genuinely blocks: a real ambiguity/contradiction, a missing decision, a blocker/dependency, a false premise, an FE/BE divergence. In the pre-read it renders as a single **`**⚠️ Offene Frage:**`** line. A benign *fact* (e.g. "der Fix liegt im geteilten Repo", "das Flag muss ans FE durchgereicht werden") is **not** an open question — fold it into the explanation paragraph, no ⚠️. If the ticket is well-defined, return **no** open question at all and the pre-read shows **no concern line** — silence is the signal (do **not** write "Keine — gut definiert."). The ⚠️ must mean "here is a real decision/problem", so the reader can scan for it; **never** manufacture one to have something to say. Aim for most tickets to carry none.
   - **SP estimate** — a single Story Points value **from the scale**, plus **confidence** (high/medium/low). Derive it by naming the anchor it most resembles, but keep that anchor rationale in your *returned analysis* for the walkthrough — it is **not** rendered into the pre-read's `SP:` line (which is number + confidence only). If already estimated in Jira, note the existing value and whether you agree.
   - **Flags** (only if they apply, one word each): `NEEDS-SPIKE`, `SHOULD-SPLIT`, `ALREADY-ESTIMATED`. Omit the line if none.
5. **Never invent behaviour to make a number or a sentence work, and never invent a concern to fill space.** If a genuine unknown blocks the estimate, that's a real concern — say so and give a low-confidence number. Otherwise stay silent. An honest "well-defined, estimate N" beats a padded list of pseudo-questions.

## 5. Write the pre-read (one artifact)

Everything goes in **one** file. A refinement pre-read is **not repo-specific** — the RTM Jira project carries tickets for *all* rtm-related repos, so a sprint spans several repos. File it at the **project level**, not under a single repo folder (unlike the per-ticket `work-log/<repo>/<TICKET>/` artifacts written by `/review` and `/spec`, which are genuinely repo-specific):

```bash
mkdir -p ~/code/knowledge/work-log/refinement/<sprint-slug>
```

Use a filesystem-safe `<sprint-slug>` derived from the **full sprint name including its project prefix**, so KW numbers can't collide if another Jira project's sprint is ever refined (e.g. `RTM 2026 KW 30-32` → `rtm-2026-kw-30-32`).

**Language: write the whole pre-read in German** — it's the team's working language and the user reads it directly. Keep ticket keys, code identifiers (`FilterDocumentationTree`, `has_maintenance`, …), and the fixed flag labels (`NEEDS-SPIKE`, `SHOULD-SPLIT`, `ALREADY-ESTIMATED`) as-is. Write `pre-read.md`:

```
# Refinement Pre-Read — <sprint name>
<Sprint-Ziel / Zeitraum, Ticket-Anzahl, Erstellungsdatum; Hinweis: Reihenfolge = Jira-Backlog (Rank); RTM nutzt EIN Story-Points-Feld.>
[→ Sprint in Jira öffnen](https://jira.redicals.de/issues/?jql=sprint%20%3D%20%22<sprint name, URL-encoded>%22%20ORDER%20BY%20Rank%20ASC)

⚠️ markiert eine echte offene Frage/ein Problem. Tickets ohne ⚠️ sind gut definiert.

## Tickets (Backlog-Reihenfolge)

### <n> · [<KEY>](https://jira.redicals.de/browse/<KEY>) — <title>

**SP: <Wert>** (<Konfidenz>)<, falls in Jira schon geschätzt: „ · bereits in Jira">

<EIN klarer Absatz, 3–6 Sätze. Was das Ticket will, wo im System (RTM-Subsysteme/Begriffe benennen), und die Einschätzung: klar genug zum Umsetzen? Was es grob berührt. Bei schlecht geschriebenen Tickets hier entschlüsseln.>

**⚠️ Offene Frage:** <NUR wenn echt — höchstens das EINE, das die Umsetzung/Schätzung wirklich bewegt, als „Problem → warum es zählt". Reiner Fakt gehört in den Absatz, nicht hierher. Ist das Ticket gut definiert: diese Zeile GANZ weglassen — kein „Keine — gut definiert.">

**Flags:** <NEEDS-SPIKE / SHOULD-SPLIT / ALREADY-ESTIMATED — nur wenn zutreffend; Zeile ganz weglassen, wenn keine>

<... pro Ticket wiederholen, in Backlog-Reihenfolge, jeweils mit `---`-Trenner dazwischen ...>

## Ergebnisse der Durchsprache  ← fürs Team-Refinement
<Wird während der Durchsprache (Schritt 6) befüllt — eine Zeile pro Ticket, siehe unten.>
```

Keep it lean and give it air: **one** explanation per ticket, no summary table, no consolidated question list, no totals block restating the rows. **The `SP:` line is the number + confidence only — no rationale sentence, no anchor tacked on** (the anchor is the subagent's internal calibration, not something the user reads out). A **blank line between every section**, and a `---` separator between tickets — never crammed together. **Every ticket heading links to its Jira issue** (`[<KEY>](https://jira.redicals.de/browse/<KEY>)`), and the top carries a **sprint link** (a JQL-search URL for the sprint name, URL-encoded). Write incrementally as subagents return.

## 6. Durchsprache — walk the tickets with the user (interactive)

This is the core of the new flow. After the pre-read is written, go through the tickets **in backlog order** (postponed ones move to the end) and settle an SP per ticket **with the user**. **Conduct this in German.**

For each ticket, ask the user with **`AskUserQuestion`** (one question, `header` = the ticket key). Put a 1–2 line recap in the question text ("<KEY>: <was es will, in einem Satz>. Bedenken: <keine / kurz>. Mein SP: <N>."). Offer these options:

- **„SP <N> passt"** — accept the draft. → record the number.
- **„SP anpassen"** — retune. **Free text can only be typed via the *Other* field** — the preset options take no user-typed note in the TUI (don't instruct the user to "add a note to the option"). So the user retunes by choosing *Other* and typing e.g. `5`, or picks „SP anpassen" and you ask a one-line follow-up for the number. → record their number.
- **„Ich habe eine Frage"** — the user types the question (in the note / *Other*). → **you answer it** from code (`$ro`) / Jira / Confluence / docs, then **re-ask the same ticket** with the same options. Do not move on until it resolves to accept/retune/postpone/pause.
- **„Ticket zurückstellen"** — postpone. → move it to the **end** of the queue and continue; revisit at the end.

Tell the user in the question text they can also pick *Other* and type **„pause"** to stop the round-through at any point.

After each ticket resolves to an SP (accept or retune), **immediately write/update its bullet** in the `## Ergebnisse der Durchsprache` section. **Keep the list in Backlog (Rank) order, not resolution order** — a postponed ticket, once decided, is inserted back at its original Backlog position, not appended at the end. (Pre-seed the 14 bullets in Backlog order and fill each in place, or insert each at its rank slot.)

```
- <KEY> — SP **<final>** <(angenommen | angepasst von <draft>) ; ggf. kurzer Hinweis>
```

Writing per ticket means **pause is free** — progress is already saved. On pause, stop asking, tell the user the results so far are in the file, and that a later session can resume from the first ticket without a bullet. When every ticket has a bullet, present the results list in chat and point to the file. The user takes these numbers into refinement and only has to read out their estimate. **Never write anything to Jira.**

---

## Refreshing the calibration

The anchor table in section 3 is a manual snapshot. To refresh: query recently-completed RTM tickets that carry Story Points and re-derive the anchors, then replace the table and the snapshot date.

```
project = RTM AND "Story Points" is not EMPTY AND statusCategory = Done AND resolutiondate >= "<~12 months ago>" ORDER BY resolutiondate DESC
```
`search_jira` does **not** return the SP value — open each issue and read `customfield_10005` (the single Story Points field). Sample ~50 tickets across Stories and Bugs, **excluding** deployment / Renovate / external-firmware ops stories (they carry SP but aren't representative dev work). Rebuild the "SP → example tickets" anchors and the notes.
