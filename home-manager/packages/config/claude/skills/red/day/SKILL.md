---
name: day
description: Daily organisation on top of the /work state files — morning: what waits on me, what is in progress at which phase, what is startable from Jira, what is blocked or parked, plus a suggestion for today; evening: collect what actually happened (gitday across all worktrees, state-file log lines, Jira updates, PRs) and draft the obligatory Slack status text, then archive both to work-log/daily/<date>.md. Use when the user asks what to do today, wants an overview of open tickets, or wants the end-of-day status ("was steht an", "/day", "/day abend", "Feierabend, Status bitte", "was haben wir heute geschafft").
argument-hint: "[morgen | abend] [YYYY-MM-DD]"
model: opus
effort: low
allowed-tools: Read Grep Glob Write Edit Skill Bash(gitday:*) Bash(wl:*) Bash(wl-copy:*) Bash(wl-paste --list-types) Bash(xclip:*) Bash(git worktree list:*) Bash(git log:*) Bash(git status:*) Bash(mkdir:*) Bash(mv:*) mcp__devtools-mcp__get_datetime mcp__devtools-mcp__get_current_user mcp__devtools-mcp__search_jira mcp__devtools-mcp__read_jira_issue mcp__devtools-mcp__list_gitea_pull_requests mcp__devtools-mcp__search_gitea_pull_requests mcp__devtools-mcp__list_gitea_pull_request_reviews mcp__devtools-mcp__list_gitea_pull_request_comments
---

# Day (red / work)

Two modes, one data model. Both read the same sources; the morning mode turns
them into a plan, the evening mode into a status text and an archive note.

Mode from the argument or the clock (`get_datetime`): before 13:00 → `morgen`,
otherwise `abend`. An explicit `morgen`/`abend` wins. An optional date runs
the evening mode for that day (useful for a forgotten status).

## Sources (collect once, in this order)

Every external source gets **one attempt**. Unreachable → say so in one line
and continue with the rest. Never block the whole overview on Jira.

1. **Clock and identity:** `get_datetime`; `get_current_user` for the Jira
   account. Git author is `git config user.email` (gitday handles that).
2. **State files:** `wl --all` gives one line per ticket (phase, gate,
   updated, session age, next step); `wl <TICKET>` the open questions and
   the last log lines. Evening: also read the `## Log` lines dated today and
   gates that moved to `passed` today from the state files directly. Ignore
   `phase: done` older than 7 days.
3. **Git:** `gitday` (morning: default, i.e. since midnight — mostly shows
   dirty/unpushed worktrees; evening: default too). Only checkouts with
   activity are printed. `gitday --since yesterday` when a Monday needs the
   weekend. The same commit can appear under several checkouts (branches
   share history, rebases change hashes) — **dedupe by hash, then by identical
   subject**, and attribute a commit to the checkout whose branch name
   carries the ticket from the commit message.
4. **Jira, morning:** `search_jira` with
   `assignee = currentUser() AND statusCategory != Done ORDER BY status ASC, Rank ASC`.
   Fields: key, summary, status, issuetype, priority, updated.
   A second query with `… AND sprint in openSprints()` marks which of them
   are in the current sprint; the rest are later sprints or no sprint.
5. **Jira, evening:** `search_jira` with
   `assignee = currentUser() AND updated >= startOfDay() ORDER BY updated DESC`
   plus, when the connector supports it,
   `status CHANGED BY currentUser() AFTER startOfDay()`.
6. **Gitea:** open PRs authored by me (`list_gitea_pull_requests` /
   `search_gitea_pull_requests`); for each, reviews and comments newer than
   the last daily note. Plus open PRs that request my review; for each, the
   ticket key from title or branch and its assignee (`read_jira_issue`).
   Skip silently if the tools are unavailable.
7. **Previous daily note:** `~/code/knowledge/work-log/daily/<yesterday>.md`
   (or the latest one) for carry-over items.

## Morning — „Was steht an?"

Join the sources by ticket id. Output in German, at most ~25 lines, four
buckets, empty buckets omitted:

**Wartet auf dich** — state files with `gate: open` (`wl --open`; the first
line of the `## Gate` block says what is asked), PRs with new review
comments, Jira tickets that moved to a status that needs me (e.g. back from
QA), review requests whose ticket is assigned to me. One line each: ticket ·
what is being asked · where (`/work RTM-… ` or the PR). A PR is ready to
review only once its author assigned the ticket to me — a Gitea request
alone is not; those get at most one line „n Review-Anfragen, Ticket noch
nicht zugewiesen".

**In Arbeit** — state files with `gate: none`/`passed` and phase ≠ done/parked,
plus worktrees with dirty or unpushed changes that have **no** state file
(flag those: „untracked, kein state.md"). One line: ticket · phase · step ·
next step.

**Angehbar** — Jira tickets assigned to me without a state file and without a
worktree, **current sprint and on Accepted only**, in Jira order. One line: key · summary ·
status. Do not estimate, do not explain the ticket — that is `/work`'s
assess phase. Tickets from a later sprint or not yet on Accepted appear
only when nothing in the current sprint is left, marked „(Ausnahme:
späterer Sprint)" / „(Ausnahme: nicht Accepted)".

**Blockiert / geparkt** — `phase: parked` with its note; Jira tickets in a
blocked status; open questions older than 3 days.

Close with **Vorschlag für heute:** one or two items, each with the command
that starts it (`/lead start RTM-…`, or `/work RTM-…` inside its worktree),
chosen by: open gates first (they block the pipeline), then in-progress
work nearest to done, then the top Jira item of the current sprint. Both
rules above hold here too: no review without an assigned ticket, an
exception ticket only when the sprint has nothing startable left and
marked as such. State the reason in half a sentence.

Nothing is written in the morning mode.

## Evening — „Was haben wir heute geschafft?"

1. **Facts first.** Build a private list from the sources: commits (from
   gitday, grouped by ticket via the `RTM-\d+` in the message), state-file log
   lines of today, gates passed, PRs opened/updated/merged, Jira transitions,
   reviews given. Deduplicate by ticket. Uncommitted work counts as „in
   Arbeit", not as done.
2. **One question, at most.** Ask the user for what git and Jira cannot see
   (meetings, support, pairing, reviews done verbally) — a single prompt,
   answer optional. Skip it when the user said „nur Entwurf".
3. **Voice and format** come from the work-brain: grep
   `~/code/knowledge/work-brain/index.md` for `slack` / `status` and read the
   matching practice note (`practices/slack-status-format.md`, filed
   2026-10-06). It holds Tobias' own examples and the pattern below; the
   note wins over this summary when they differ.
   - The pattern: first line `Status:`, blank line, then one bullet per
     ticket `RTM-XXXX Kurztitel` (his own two-to-four-word short form) with
     an indented sub-bullet of one or two sentences in the first person —
     where it stands, what happens next or what it is stuck on. Several
     small tickets with the same state may share a line. Reviews go into
     one `Reviews` block (done / still on it), or just „Einige Reviews".
     Casual tone, colleagues by first name, an occasional emoji. **Not in
     the status:** meetings, pipeline or tooling internals (at most in
     passing), anything git, Jira or Tobias did not state.
   - Only tickets that **moved today** — a Jira status change counts even
     without a commit, an unchanged open gate does not. „Ready to Merge"
     always reads „Ready to Merge -> müsste jemand für mich übernehmen,
     darf nicht :slightly_smiling_face:"; a finished pipeline ticket is
     „Bereit fürs Review", nothing more. Reviews only where he worked
     (gemacht / noch dran), not the newly assigned ones. Never infer the
     state of hand-worked tickets from commits: put „<Stand von dir>".
   - If the note is missing on this machine: ask once for two or three real
     examples, use them, and **offer** to file them via the `brain` skill
     (routing: work-brain, type practice) — don't write the brain yourself.
4. **Draft the text** in a fenced code block so it can be copied as is.
   Facts only; every line traces back to a commit, a state line, a Jira
   change, or the user's answer. Never post it anywhere — Slack is the user's
   hand.
   - **Jira links for Slack:** Slack's composer keeps hyperlinks only from
     HTML in the clipboard; `<url|Text>` and Markdown pasted as plain text
     stay plain. So besides the code block, write the same text as HTML
     (`<p>Status:</p>` plus nested `<ul>`, every `RTM-XXXX` as
     `<a href="https://jira.redicals.de/browse/RTM-XXXX">RTM-XXXX</a>`) to
     a file in the scratchpad and run `wl-copy --type text/html < file`
     (Wayland; `xclip -selection clipboard -t text/html` on X11). Say in
     one line that the clipboard holds the linked version. When Tobias
     edits the draft in the chat, copy the edited version again.
5. **Archive:** write `~/code/knowledge/work-log/daily/<YYYY-MM-DD>.md`:

   ```
   ---
   date: 2026-09-16
   tickets: [RTM-1234, RTM-5678]
   ---

   # 2026-09-16

   ## Fakten
   - RTM-1234 · 3 commits · build → review · Loop nach 2 Runden fertig
   - PR 1988 eröffnet
   - …

   ## Status-Text
   <the final text as sent, updated if the user edits it in the chat>

   ## Übertrag
   - <what is open for tomorrow — feeds the next morning's „Wartet auf dich">
   ```

   If the file exists for that date (`/lead` creates it in the morning and
   appends a `## Verlauf` section during the day), keep `## Verlauf` as it
   is and rewrite only `## Fakten`, `## Status-Text` and `## Übertrag` (a
   rerun refines, it does not duplicate). `mkdir -p` the folder on first
   use. Don't commit the store unless asked.
6. **Archiv-Kandidaten im work-log.** Ticket folders under
   `~/code/knowledge/work-log/<repo>/<TICKET>/` are archive candidates when
   the Jira ticket sits in statusCategory Done (Fertig or Won't Do) **and**
   no open PR references the ticket any more (`search_gitea_pull_requests`
   for the key, state open). For review folders (a colleague's PR) the bar
   is lower: as soon as that PR is merged. The folders `_junk`, `misc`,
   `daily`, `refinement` and `sprint-review` are not tickets and stay
   untouched, as does `_archiv` itself.
   - List the candidates, one line per ticket: key · Jira status · last PR
     (number and state). **Do not move anything on your own.** Only after
     an explicit „ja" from the user, move each folder with
     `mv ~/code/knowledge/work-log/<repo>/<TICKET>
     ~/code/knowledge/work-log/_archiv/<repo>/<TICKET>` (`mkdir -p` the
     repo folder first). The repo level is mandatory: `wl` looks for
     `*/*/state.md` at depth 3, so a folder directly under `_archiv/`
     would keep showing up in `wl`. Never delete anything.
   - Decided by Tobias on 2026-10-15; the first run that day moved 75
     folders, so the rule is in force, not a proposal.

## Stay in scope

- Read-only against Jira and Gitea. No transitions, no comments, no Slack.
- No project source files are read or changed — `gitday` is the only view on
  the code.
- Write only `work-log/daily/<date>.md`. The one other write is the
  evening archive step: moving whole ticket folders into
  `work-log/_archiv/<repo>/<TICKET>/` with `mv`, and only after the user
  said yes to the listed candidates — never on your own, never a delete.
  State files belong to `/work`; if the overview reveals a stale one, say
  so and leave it.
- Keep it short. The morning overview is read in a minute; the status text
  is read by a team in ten seconds.
