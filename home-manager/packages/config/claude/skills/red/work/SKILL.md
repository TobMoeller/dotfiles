---
name: work
description: Drive a Jira ticket through the development pipeline — assess → spec → plan → implement → verify → review → acceptance — as an orchestrator that delegates every phase to a specialist subagent (analyst, planner, plan-verifier, implementer, step-verifier, reviewer, writer) and escalates conflicts to the auditor. State lives in work-log/<repo>/<TICKET>/state.md, so any session resumes from disk; gates are written there, never asked interactively. The flow is documented in ~/.claude/PIPELINE.md. Use when the user wants to start, continue, inspect, answer a gate of, or park a ticket (e.g. "work on RTM-1234", "weiter mit RTM-1234", "/work RTM-1234 status", "/work RTM-1234 abnehmen", "park RTM-1234: warte auf QA").
argument-hint: "<RTM-XXXX> [status | park <Notiz> | redo <phase> | nacharbeiten <Notiz> | commits manual|auto | siehe fragen.md | diskussion <n> | <Antwort auf das offene Gate>]"
model: opus
allowed-tools: Read Grep Glob Edit Write Agent Skill ListAgents SendMessage Bash(git status:*) Bash(git diff:*) Bash(git log:*) Bash(git show:*) Bash(git branch:*) Bash(git rev-parse:*) Bash(git merge-base:*) Bash(git fetch:*) Bash(git worktree list:*) Bash(git ls-files:*) Bash(git add:*) Bash(git commit:*) Bash(mkdir:*) Bash(date:*) Bash(wl:*) Bash(wl-write:*) Bash(docker compose ps:*) mcp__devtools-mcp__get_datetime mcp__devtools-mcp__read_jira_issue mcp__devtools-mcp__list_gitea_pull_requests
---

# Work a ticket end to end (red / work) — orchestrator

One ticket, one branch, one worktree, one state file, **one orchestrator that
does no work itself**. This session reads `state.md`, delegates each phase to
a specialist (Agent tool, the profiles under `~/.claude/agents/`), records
the result, and either continues or writes a gate and stops. The transcript
is never the source of truth — the state file is. That keeps this context
small (the specialists carry the code in theirs), makes the pipeline
resumable across sessions, and lets `/lead` steer a worker without seeing
its screen. The human-readable description of the whole flow is
`~/.claude/PIPELINE.md`; this file is the executable version.

Specialists and what they return (each ends with an `ERGEBNIS:` block you
parse; never re-derive their work):

| Agent | Phase | Returns |
|---|---|---|
| `analyst` | assess, spec · answers Rückfragen (for the chat) | ticket facts, DoD, TLDR, `spec.md` (always) or Diagnose with the technical questions under `## Entscheidungen`, the fachliche questions as sections in `fragen.md`, tasks for Tobias · `ANTWORT:` on a Rückfrage |
| `planner` | plan | `plan.md` |
| `plan-verifier` | spec (**Modus: spec**, the `SPEC` check) · every question before it reaches Tobias (**Modus: fragen**) · plan (**Modus: plan**) | pass / fail / unsicher · spec: question classes, tasks · fragen: pass/fail per question |
| `implementer` | implement (per step, uncommitted) | diff, checks |
| `step-verifier` | per step (M, L) · whole branch (CHECKS) · refute findings | pass / fail / unsicher · WIDERLEGT list |
| `reviewer` ×2 (×3) | review | findings |
| `writer` | accept | `handover.md`, `ABNAHME` questions in `fragen.md`, PR title, Jira text |
| `auditor` (Fable) | escalation · once per spec round for the technical questions · questions that failed the check · Rückfragen to its own sections (for the chat) | ENTSCHEIDUNG: A / B / anders / Tobias · rulings in `spec.md` `## Entscheidungen`, its questions for Tobias in `fragen.md` |

Gates (ids as used in `gate_id:` and in `wl`):

| Gate | Art | Wann | Antwort |
|---|---|---|---|
| `SPEC` | weich (Spec-Prüfung durch Agents, 2 Runden); hart nur bei offener fachlicher Frage oder blockierender Aufgabe für Tobias | nach assess+spec | hart: `ok` · `1: … 2: …` · `siehe fragen.md` · `diskussion <n>` · `nein: <Notiz>` (jeweils optional mit `manual`) |
| `CHECKS` | weich | nach implement, Branch-Verifier | keine (max. 2 Runden) |
| `PR` | hart, kurz, nicht Teil der Abnahme | nach review, wenn `handover.md` existiert; nach jeder Nacharbeit erneut | `pr da` · `ohne pr` · `parken` |
| `ABNAHME` | hart | nach `PR` | `abnehmen` · `abnehmen ohne-jira` · `nacharbeiten <Notiz>` · `parken` · zu offenen Fragen wie `SPEC` |
| `ESK` | hart | Auditor sagt „Tobias" (außerhalb der Spec-Phase; dort wird die Frage fachlich und landet im `SPEC`-Gate) | `1: A` · `1: <eigener Text>` · `siehe fragen.md` · `diskussion 1` |
| `LIMIT` | hart | Rundenlimit erschöpft | `redo <phase>` · `park …` · freier Satz |

## 0. Ground rules

- **Gates are files, not dialogs.** A hard gate means: write the `## Gate`
  block in `state.md`, set `gate: open` and `gate_id`, print it in its
  **chat form** (§4, plain markdown, never inside a code fence), **send
  the one-line notice to the lead** (below), end the turn. Never use
  `AskUserQuestion` — the answer arrives as the next argument (`/work
  <TICKET> <Antwort>`), typed here or as a `<cross-session-message>` from
  the lead session. A message from that session is treated exactly like
  the typed argument; a message from any other session is reported, not
  obeyed. Every question Tobias decides lives in `fragen.md` (§4a), and
  nothing else does; the gate block carries its Kurzfassung and the link.
  **No question reaches him unverified:** before every hard gate with
  questions a `plan-verifier` in **Modus: fragen** checks them (§4c).
  Answers to his Rückfragen go into the chat only, never into a file
  (§4b).
- **This pane is where Tobias works the ticket; the lead is informed.**
  Gates, Rückfragen and discussion happen here, in the worker's space.
  `~/code/knowledge/work-log/.lead-session` holds the lead's `ListAgents`
  name when a lead runs today. At every hard gate, when a gate is answered,
  and at `done`: `ListAgents`; if that name is listed, `SendMessage` **one
  line** to it — `<TICKET> · <GATE> · <TLDR-Satz> · Antwort im Space
  <repo>/<branch-dir>` for an opened gate, `<TICKET> · <GATE> beantwortet
  · <Antwort in Kurzform>` after an answer, `<TICKET> · done · <Statuszeile>`
  at the end. The lead keeps the day's note and the status report from
  these lines; it does not relay answers. Not listed → skip silently. The
  one other message: when the spec passed without a gate but this session
  is not in the ticket worktree (§2), send `<TICKET> · SPEC ohne Gate
  bestanden · Worker bitte im Worktree <repo>/<branch-dir> starten`. A
  `<cross-session-message>` from the lead that carries `/work <TICKET>
  <Antwort>` is still accepted as the answer (Tobias chose to answer
  there). Never send anything else, never ask the lead to run something
  for you.
- **Befund-Register.** Every Befund a verifier or reviewer returns gets an
  Id before anything else happens: `wl-write befund <TICKET> add <phase>
  <Kriterium> "<Agent> r<n>" "<Befund in einem Satz>"` → `B07`. From then
  on the Befund is addressed by its Id: in the author's brief (`B07 ·
  <Kriterium> · <Text>`), in the author's answer (`umgesetzt` or
  `zurückgewiesen: <Beleg>`), in the verifier's re-check, in the auditor's
  ruling. Status via `wl-write befund <TICKET> set B07[,B08,…] <status>
  [<wer/was>]` (all Ids that get the same status in one call); statuses:
  `offen`, `umgesetzt`, `zurückgewiesen`, `Auditor: bestätigt`, `Auditor:
  verworfen`, `Hinweis`. **Every verifier and reviewer brief
  carries the register** (`wl-write befund <TICKET> list alle`) with the
  rule: a decided Id is not raised again without a new Beleg, and then as
  a new row that names the old Id. A point can cost the pipeline one round,
  not three.
- **Zurückweisung.** An author (analyst, planner, implementer) may answer a
  Befund with `zurückgewiesen: <Beleg>` instead of applying it. After the
  author returns, all rejected Ids of that round go in **one** auditor call
  (verifier position and author position verbatim, both Belege); the
  auditor's `bestätigt`/`verworfen` per Id is final, goes into the register
  and never comes back. A confirmed Befund goes to the author once more as
  a normal re-round; a dismissed one is closed. These auditor calls do not
  count against `auditor:`.
- **Ein Rücklauf pro Kriterium.** A verifier Befund names the criterion of
  `kriterien.md` (next to this SKILL.md) it violates, or it is a `Hinweis`.
  When the same criterion fails again after the author's rework, the
  question is not sent around a third time: the auditor rules on it (one
  call, both positions), then one last verifier round. Hinweise never cost
  a round: they are registered as `Hinweis` and handed to the next agent
  that is briefed anyway.
- **Visible progress.** Tobias may read along in this pane. Print one short
  German line per phase transition and per implement step (`RTM-4100 ·
  implement · Schritt 2/4 · FirmwareRule · verifiziert`) in the same
  message as the next tool call, not as a separate turn.
- **End a turn only with a tool call or a written gate.** A progress summary
  that announces the next step, or an offer to continue, stops the worker
  until someone resumes it. Put status notes in the same message as the next
  tool call. Sole exception: the answer to a Rückfrage or a reply in
  discussion mode (§4b), where the gate stays open and the turn ends with
  the answer to Tobias.
- **Commits happen after verification, by this session.** The implementer
  leaves the tree uncommitted. After a step is verified: `git add <files of
  the step>`, then with `commits: auto` (the default) `git commit -m
  "<Commit line from plan.md>"` — the message is exactly that one line,
  no trailer, no `Co-Authored-By`, nothing the team's
  `.claude/rules/commit-messages.md` does not ask for. The commit-guard
  hook allows exactly that;
  the global „commit only when I ask" rule is satisfied by `commits: auto`,
  the default `state-template.md` carries — Tobias' standing decision, since
  the spec no longer always stops at him. He opts out per ticket with
  `manual` (the `commits manual` argument, the word `manual` in any gate
  answer, or in the lead's start prompt). Never change the line on your own
  initiative, and switch back to `auto` only on his explicit `commits
  auto`. With `manual` the step stays staged and the commit line goes to
  `## Commits`. **Never push, never create, merge, approve or change a
  PR** — pushing and the PR are Tobias' hand (gate `PR`), merging always,
  also after `abnehmen`. Never amend. Gitea is read-only for this
  session; the only Jira write is the PR link at `abnehmen` (below).
- **One worker per ticket.** On start write `session: ${CLAUDE_SESSION_ID}`
  and `session_name: <your name from ListAgents' first line>` into the
  frontmatter; the lead addresses you by that name. If a different id is
  there and the `updated` time is less than 10 minutes old, another
  session is probably working this ticket: print that and stop instead of
  taking over.
- **Write state before you stop, in one call per transition.** Every
  `wl-write` call is a full-context turn of this session, so a phase
  transition is **one** command:
  `wl-write phase <TICKET> <phase> [--step n/N] [--round n] [--gate
  none|open|passed] [--gate-id ID] [--next "<Nächster Schritt>"] [<key>
  <value>]… "<Log-Satz>"` — sets the frontmatter, replaces `## Nächster
  Schritt`, appends the `## Log` line and `updated:`. Between transitions
  only what changed: `wl-write set <TICKET> <key> <value> [<key>
  <value>]…` (several keys in one call), `wl-write log <TICKET> <phase>
  "<Satz>"`, `wl-write next <TICKET> "<Text>"`. Edit `state.md` yourself
  only for the sections no command covers (`## Gate`, `## DoD`, `##
  Entscheidungen`, `## Offene Fragen`, `## Für Tobias`, `## Commits`, `##
  Gates`), and collect those edits into as few calls as the content allows.
- **Timestamps and numbers come from `wl-write`, never from you.** Never
  type a time or a running number yourself — the agents' estimated clocks
  were hours off, and `/day`, `wl` and the Prüfverlauf rely on these
  values. Log example: `- 2026-09-30 10:42 · implement · Schritt 2/4
  FirmwareRule angepasst · verifiziert · committed a1b2c3d`.
- **Prüfverlauf — every agent call leaves a trace** in `$store/pruefung/`,
  so Tobias can see afterwards how often a phase looped and whether the
  objections were worth it. After each agent returns, **one** call:
  `wl-write runde <TICKET> <phase> <runde> <agent> <agent-id> <ergebnis>
  <befunde> "<Ausgang>"` — `agent-id` from the spawn result, `befunde` the
  Ids (`B03 B04`) or `-`, `Ausgang` what this session does with the result
  (`umgesetzt → <Agent>`, `Hinweis → <nächster Agent>`, `Zurückweisung →
  Auditor`, `Gate <ID>`, `pass → <Phase>`). It appends the verlauf row
  **and writes `pruefung/<nr>-<phase>-<agent>-r<n>.md` itself**, with the
  brief and the agent's final report copied from its transcript. Never
  retype a result block into a file; only when the command prints „kein
  Transkript" append the block with Edit. `wl <TICKET> --runden` joins the
  rows with the transcripts for turns, tokens and duration; the writer
  puts `--sum` and the register into `handover.md`. No judgement, no
  summary: the files are the record, the judgement is Tobias'.
- **Don't re-read what is settled.** `spec.md`, `plan.md` and
  `## Entscheidungen` are binding. Reopen only when a verifier or the code
  proves them wrong, then record a new decision.
- **Continue an agent for its second round, start fresh for a new phase.**
  An agent that has read the code once (verifier, reviewer, analyst,
  planner) answers a re-check in 3–5 calls when it is continued, and in
  10–15 when it is spawned again; a continued agent also keeps its warm
  cache. So: after a `fail`, `Zurückweisung`, auditor ruling or Nacharbeit
  the **same** agent gets the next round via `SendMessage` to its agent id
  (from the spawn result; record it with `wl-write set <TICKET>
  <rolle>_id <id>`, roles `analyst_id`, `planner_id`, `verifier_id`,
  `reviewer_ids` (comma-separated), `implementer_id`). The follow-up
  brief is short: round number, the open Ids with their texts (or the
  Nachtrag), what changed since (commit, files), the register; nothing it
  already read. Spawn fresh when: the id is from another session
  (`session:` changed), the agent's last row in `wl <TICKET> --runden` is
  older than 60 minutes (cache gone, context stale), the role changes
  (planner never becomes implementer), or the earlier brief was wrong in
  substance (then a fresh mind, not a corrected one). The implementer is
  the exception: its round 2 is usually only „run the checks again" and
  is cheap either way; continue it when the rework touches the code it
  wrote, spawn fresh when the Nachtrag is self-contained. A continued
  agent is logged like a new call (`wl-write runde` with the same id;
  `wl --runden` attributes the calls since its previous row).
- **Self-contained agent briefs.** Subagents inherit nothing from this
  skill. Every brief carries: ticket id, store path, worktree path, which
  files to read, the exact task, the exact expected result block, and the
  relevant `## Entscheidungen` lines verbatim; for analyst, auditor and
  writer also the `fragen.md` path and the section numbers concerned, and
  for the auditor's technical questions the `spec.md` path.
- **Shell: one plain command per call**, no `$(…)`, no pipes.
- **User-facing output is German**, compact, ends with the state line:
  `→ <TICKET> · <phase> · <gate> · Schritt <n/N> · nächster Schritt: <…>`.

## 1. Resolve the ticket, the store, the mode

`git rev-parse --path-format=absolute --git-common-dir` → `main` is its
parent directory, `repo` its basename, `store` is
`~/code/knowledge/work-log/<repo>/<TICKET>` (`mkdir -p`). Ticket id from the
argument, else from the branch name (`RTM-\d+`, last match), else ask once
in plain text and stop.

| Argument | Action |
|---|---|
| *(none)* | Read `state.md`, print the state line. `gate: open` → read the answers in `fragen.md` (§4a); none written → print the `## Gate` block again and stop. `discussion:` set → say which question is being discussed and wait for his message (§4b). Else continue at `phase` / `step`. No state file → **assess**. |
| `siehe fragen.md` (while `gate: open`) | Same as *(none)* with `gate: open`: the answers are in the document (§4a). |
| `diskussion <n>` (while `gate: open`) | Question n moves to this pane (§4b). |
| `status` | `wl <TICKET>` output. Nothing else. |
| `park <Notiz>` | `phase: parked`, note into `## Nächster Schritt`, log line. Stop. |
| `redo <phase>` | `phase` back to that phase, `gate: none`, `step`/`round` reset, log why. Continue. |
| `nacharbeiten <Notiz>` | Only in `accept`/`done`: the note becomes a rework step (section 3). Continue. |
| `commits manual` · `commits auto` | Tobias' commit-mode decision: set `commits:`, log line. Applies from the next step; already committed steps stay. Then as *(none)*. |
| anything else while `gate: open` | The answer to the open gate (see its row above). A decision is handled per §4a (status into the section heading, answer verbatim into its `Antwort:` line, `## Entscheidungen`, log line), `gate: passed` once every question is decided, continue. A `<n>: <Text>` that is not one of the offered options (context, a correction, a question back) is still about question n: a decision or a Rückfrage (§4b), never rejected for its form. With `discussion:` set, plain text typed in this pane is a discussion message (§4b). |
| anything else while `gate: none` | Not a valid mode: print the state line and stop. |

Existing artifacts in `$store` count: a `spec.md` from an earlier `/spec`
means the spec phase is done (unless older than the ticket's last Jira
update — then the analyst checks it); `review.md` is context only.

## 2. Where am I? (context check)

`git rev-parse --show-toplevel` and `git rev-parse --abbrev-ref HEAD`,
separate calls.

- toplevel == main → **main checkout**: assess/spec, including the spec
  check, may run (read-only). Nothing after it may.
- toplevel != main and the branch contains the ticket id → **ticket
  worktree**: everything may run. Write the real values into `state.md`
  (`branch:`, `worktree:`) now; they override whatever the analyst guessed.
  Subagents start in this cwd, which is why the worker session lives here.
- Otherwise → stop, wrong worktree.

From **plan** on, additionally the worktree must be ready: `.wt-ready`
exists in the worktree root (`wt add`'s bootstrap writes it), **or** for a
worktree created before that marker existed, `vendor/` and `.env` are
present. `.wt-failed` → stop and say so. `docker compose ps` shows the
stack up. A missing worktree: finish the current phase, write state, run
the `worktree` skill (`worktree <TICKET> <slug> --yes`), then print the
handoff (section 5).

## 3. Phases

### assess + spec — understand, check, decide · `analyst` → `plan-verifier` (Modus: spec) → `auditor` (technical questions) → `plan-verifier` (Modus: fragen) → gate `SPEC` only when needed

Tobias does not review the spec line by line; agents check it against
`kriterien.md` S1–S6 and he sees the whole at `ABNAHME`. But he **is**
asked before coding whenever the ticket leaves something open, a
requirement would cost far more than the ticket suggests while a simpler
way exists, a requirement is bad for the user, or the build rests on an
assumption about real data — the question classes of §4c. Those questions
reach him after one check of their form, never after rounds of agents
deciding whether he may see them. What he must not get is invented
scenarios and purely technical design choices; those the agents settle.

- **Brief:** ticket id, store, repo path, the existing branch name if the
  worktree exists (the analyst then does not derive one), whether `spec.md`
  exists, and a decision from the lead's start prompt verbatim.
- **On `ERGEBNIS: frage` (Jira down):** hard gate `SPEC` with the request for a
  paste; on the answer, re-brief the analyst with the pasted text.
- **On `nicht-umsetzbar`, or size `L` without an epic:** route via the
  `tickets` skill (team's ai-tooling skills: `feature-ticket-review` or
  `epic-erstellen`), log the detour, hard gate `SPEC` with that instruction.
- **Analyst exit:** `state.md` created from `state-template.md` (next to
  this SKILL.md; `commits: auto` unless the start prompt said Tobias commits
  himself → `manual`), frontmatter from the result block (`reviewers: 3`
  when size is `L`, else `2`), `## DoD` from `DOD:`, `TLDR:` kept for the
  gate, each `FRAGEN:` line into `## Offene Fragen` as an index line —
  fachlich: `- [ ] F<n> <Titel> · Gate: SPEC · Autor: Analyst ·
  fragen.md#frage-<n> · Empfehlung: <Option>`; technisch: `- [ ] T<n>
  <Titel> · spec.md#entscheidungen · Empfehlung: <Option>` — each
  `AUFGABEN:` line into `## Für Tobias` as `- [ ] <Aufgabe> · <vor dem
  Bauen | vor dem Deploy> · Warum: …`. The analyst always writes `spec.md`
  (a ten-line one for size `S`, written as if every recommendation were
  accepted) or the `## Diagnose` in `plan.md` for bugs. Technical
  questions go there, under `## Entscheidungen` as `T<n>` lines for the
  auditor; only the fachliche ones become sections in `fragen.md` (from
  `fragen-template.md`, §4a).
- **Spec check (soft, 2 rounds):** brief a `plan-verifier` in **Modus:
  spec** without the analyst's output — it reads the ticket, `state.md`,
  `spec.md`/`## Diagnose`, `fragen.md` and `kriterien.md` S1–S6 itself,
  plus the register. Register every Befund (§0), then `fail` → continue
  the analyst (its id, §0) with the Ids and texts, `round: 2`; the analyst
  answers per Id (`umgesetzt` / `zurückgewiesen: <Beleg>`); rejections →
  one auditor call (§0). Round 2 continues the same plan-verifier: it
  re-checks the open Ids and the list, not the document afresh. A criterion failing twice → auditor (§0 „Ein Rücklauf pro
  Kriterium"), then one last check; still `fail` → `LIMIT`. `unsicher` →
  auditor directly. On `pass` apply its lists: tasks are added; a `[sprache]`
  Befund replaces the TLDR with its wording; questions whose class it
  changes and `neu` questions → one re-brief of the analyst: a question now
  `technisch` moves from `fragen.md` to a `T<n>` line in the spec, one now
  `fachlich` becomes a `fragen.md` section, index lines follow (no further
  spec check round; the fachliche ones still pass §4c).
- **Technical questions → auditor, one call:** the `spec.md` path (or
  `plan.md` for bugs), the `T<n>` numbers of every open technical
  question, the `fragen.md` path. It is planned work, not an escalation:
  it does **not** count against `auditor:`; log it. The auditor writes its
  ruling into the `T<n>` line in the spec itself. Per question: an option →
  tick it (`- [x] T<n> … → <Option> (Auditor)`), one `## Entscheidungen`
  line (Quelle: Auditor), one log line; `Tobias` → the auditor has written
  a new `fragen.md` section for it, add its `F<n>` index line (`Autor:
  Auditor`). Rulings that deviate from the analyst's recommendation →
  re-brief the analyst to update the spec (no new questions). No further
  spec check round: the plan-verifier checks the plan against the updated
  spec next.
- **Question check (§4c):** when a fachliche question is open, draft the
  `## Gate` block (§4) in `state.md` with `gate: none`, then one
  `plan-verifier` in **Modus: fragen** over all open sections and the
  draft. Questions that fail do not reach Tobias (§4c).
- **Decide:**
  - **No question for Tobias left (§4c classes) and no task `vor dem
    Bauen`** → no stop.
    Log `spec · Spec-Prüfung pass (Runde n) · k technische Fragen vom
    Auditor entschieden · keine fachliche Frage · weiter ohne Gate`, mark
    the `SPEC` row in `## Gates` as `automatisch`, clear the draft gate,
    `phase: plan`, continue (outside the ticket worktree: §2/§5 handoff
    plus the handoff message to the lead). Tasks `vor dem Deploy` stay in
    `## Für Tobias`; the writer carries them into `handover.md`.
  - **Otherwise → hard gate `SPEC`**, block per §4 with the checked
    questions for Tobias and the tasks for him. Answers from the chat or
    from the document (§4a):
    - `ok` → every recommendation accepted, `vor dem Bauen` tasks reported
      done. Each question decided per §4a.
    - `1: <…> 2: <…>` → answers that deviate; `ok` is implied for the rest
      (chat only; in the document an empty `Antwort:` leaves the question
      open). Each question decided per §4a, re-brief the analyst to update
      the spec (no new questions), continue without a second stop. An
      answer that is context or a correction rather than an option: give
      it to the analyst verbatim; it settles the question → a decision as
      above; it changes the question → §4b (section replaced, re-checked).
    - A Rückfrage (a question back) → §4b: answered in the chat. No new
      round and no limit: the gate stays open until he decides; the other
      questions keep their answers, and nothing is implied as `ok` while a
      Rückfrage is open.
    - `nein: <Notiz>` → the note goes to `## Entscheidungen`, re-brief the
      analyst, spec check once more, gate again. Two `nein` → `LIMIT`.
    - `manual` anywhere in the answer → also `commits: manual`.
  On approval or automatic pass: `phase: plan`.

### plan · `planner` → `plan-verifier` (soft, 2 rounds)

- **Entry:** `SPEC` passed (automatically or by Tobias), ticket worktree ready, `git status --porcelain`
  clean apart from ignored env files (otherwise write that into `## Gate`
  as `LIMIT` and stop — never stash or discard).
- Brief the planner (store, worktree, decisions, the Hinweise from the spec
  check by Id). Then brief the plan-verifier in **Modus: plan** **without
  the planner's output** — it reads `plan.md`, `spec.md`, `state.md`,
  `kriterien.md` P1–P6 and the register itself.
- Register every Befund (§0). `fail` → continue the planner (its id) with
  the Ids; it answers per Id (`umgesetzt` / `zurückgewiesen: <Beleg>`);
  rejections → one auditor call. `round: 2` continues the same
  plan-verifier over the open Ids and the list. A
  criterion failing twice → auditor, then one last check; still `fail` →
  `LIMIT`. `unsicher` → auditor directly.
- **After an auditor ruling** (any phase): record it in `## Entscheidungen`
  (Quelle: Auditor), apply its Anweisung through the responsible agent,
  then **exactly one more verifier round**. Still not `pass` → `LIMIT`.
  `ENTSCHEIDUNG: Tobias` → gate `ESK` with the section the auditor wrote
  into `fragen.md` (§4), after it passed the question check (§4c); if it
  fails there, the auditor rules itself. Increment `auditor:` **before** each call; at `auditor:
  2` the next conflict is `LIMIT` without a call.
- A DoD item the spec cannot cover is a spec gap → `redo spec` with the gap
  as the analyst's brief, not a silent assumption.
- **Exit:** `pass`. `phase: implement`, `step: 1/N`, `round: 0`, continue.

### implement — per step · `implementer` (→ `step-verifier` for M and L, 3 rounds per step)

For step `n` of `plan.md` (from `step:` in the frontmatter, so a resumed
session continues where the last one stopped), in order:

1. Record `step_base: <git rev-parse HEAD>`; it stays fixed for all rounds
   of this step. Earlier steps are committed (`auto`) or staged (`manual`),
   so `git diff` (working tree vs. index) plus untracked files is exactly
   this step; the verifier uses that.
2. Brief the implementer: step number, the decisions, the open Hinweise
   for this step by Id, and for a re-round the open Befund Ids with their
   texts as „Nachtrag". Parse `ERGEBNIS`, `CHECKS`, `DATEIEN`, `ABWEICHUNG`,
   `BEFUNDE` (per Id `umgesetzt` / `zurückgewiesen: <Beleg>`), `UNSICHER`.
   - `ABWEICHUNG` given → `## Entscheidungen` (Quelle: Implementer).
   - `zurückgewiesen` Ids → one auditor call (§0); `bestätigt` → back to the
     implementer once; `verworfen` → closed.
   - `unsicher` → auditor with the conflict.
   - `fail` (checks red after its attempts) → the error text becomes a
     registered Befund (Kriterium I4) for a re-round (counts against the 3).
3. **Size `M` or `L`:** brief the step-verifier in **Modus: schritt** (step,
   base, the DATEIEN list, `kriterien.md` I1–I5, the register). It never
   sees the implementer's report.
   - `pass` → step 4 (Hinweise registered as such).
   - `fail` → register the Befunde, `round +1`, back to 2 with the Ids
     (implementer continued or fresh per §0); the re-check continues the
     **same** step-verifier (its id) with the open Ids and the new diff. A
     criterion failing a second time → auditor, then one last round. After
     round 3 → `LIMIT` with the open Ids and what was tried.
   - `unsicher` → auditor; its Anweisung is the Nachtrag for one more round.
   **Size `S`:** no per-step verifier; the implementer's green checks are
   enough here, the `CHECKS` gate verifies the whole branch right after.
4. `git add <DATEIEN>`; `commits: auto` → `git commit -m "<Commit line>"`;
   `manual` → append the commit line and files to `## Commits`. Log line,
   `step: n+1/N`, `round: 0`.

**Nacharbeit** (from `CHECKS`, from the review, from `nacharbeiten <Notiz>`):
append `### N+k. Nacharbeit <Quelle>` to `plan.md` with Dateien, Änderung
(the Befunde or the note verbatim), Test, Commit line
`fix(<scope>): <what> <TICKET>` (or `chore` for test-only), set `step:
N+k/N+k` and run this same loop. Never a free-form re-brief.

**Exit:** all steps done. `phase: verify`, continue.

### verify — gate `CHECKS` · `step-verifier` in Modus: branch (soft, 2 rounds)

Brief a step-verifier with **Modus: branch**, base `git merge-base
origin/develop HEAD`, `kriterien.md` B1–B5 and the register; record its
id as `verifier_id`. `fail` → register the Befunde, a Nacharbeit step
with their Ids, then `CHECKS` again **by the same verifier** (continued
with the open Ids and the Nacharbeit commit; fresh only per §0's rules).
Second `fail` on the same criterion → auditor,
then one last check; still `fail` → `LIMIT`. `pass` → write the evidence
into `## DoD`, `phase: review`.

### review — independent eyes · `reviewer` ×`reviewers:` → refute → fix

- Spawn **`reviewers:` (2, or 3 for `L` and whenever Tobias asked for a
  deeper review) `reviewer` agents in one message** with identical briefs:
  the scope commands (`git merge-base origin/develop HEAD`, `git diff
  <base>`, untracked list), the store path for `state.md`/`spec.md`, and the
  instruction to flag gaps between diff and acceptance criteria. They are
  blind to each other. Record their ids as `reviewer_ids`.
- **Merge and dedupe** (same spot + same claim → one finding, keep the
  reviewer count as information; never drop a single-reviewer finding —
  the review round lists everything, the filtering comes after). Register
  every merged finding (`Kriterium: review`).
- **Refute:** one `step-verifier` in **Modus: widerlegen** with all merged
  findings by Id (more than 10 → split over up to 5 agents). It returns
  `WIDERLEGT: ja|nein · Beleg` per Id; `ja` → `wl-write befund <TICKET> set
  Bnn Hinweis "widerlegt: <Beleg>"`; `nein` → stays `offen`. This session
  never opens the code itself.
- **Fix:** surviving findings that are not judgment calls → one Nacharbeit
  step (Ids) through the implement loop; the implementer may reject per Id
  (§0), then `CHECKS` once more (counts as its round 1 again), then the
  **re-review by the same reviewers** (continued, „nur das Delta: Commit
  <sha>, Ids …"; each confirms its own Ids as erledigt or names what is
  missing, and reports anything new the rework broke). Judgment
  calls (design, naming, scope, pre-existing code) → `## Offene Fragen`
  with a recommendation (the writer turns them into `fragen.md` sections,
  §4c filters them); a finding all reviewers share goes to the auditor
  first.
- **Exit:** log `review · n Befunde, m gefixt, k offen`, `phase: accept`,
  `gate: none`, continue.

### accept — gate `PR`, then gate `ABNAHME` · `writer`

- Brief the writer for `handover.md`: reviewer verdicts, check results,
  fixed and open findings, commit mode, `## Commits`, the open
  `## Für Tobias` tasks, the open judgment calls from `## Offene Fragen`,
  and the output of `wl <TICKET> --runden --sum` plus `wl-write befund
  <TICKET> list alle` (for its `## Prüfverlauf`).
  It reads the diff and all `## Entscheidungen` itself (Tobias saw none of
  the spec-phase decisions yet), writes each open judgment call as a
  `fragen.md` section and links it from „Offen"; add its `F<n>` index
  line (`Gate: ABNAHME · Autor: Writer`). On a rework round it adds „Diff
  seit letzter Abnahme".
- **Question check:** with `ABNAHME` questions, draft the `## Gate` block
  and run §4c over those sections. A question that does not pass is
  decided by the auditor (§4c) and the writer is re-briefed once to move
  it from „Offen" to „Entscheidungen unterwegs".
- **Gate `PR` (hard, short, not part of the acceptance):** the branch is
  done and Tobias wants to read the diff in Gitea before he accepts. He
  pushes and opens the PR himself; this session never does. `## Gate`
  block per §4 (`PR` form): what to do, the push command for this
  worktree (`git -C <worktree> push -u origin <branch>`), the PR
  (`<branch>` → `develop`, title from `handover.md`, no description), and
  where `handover.md` lies. On a later round (after `nacharbeiten`, `pr:`
  already set) only the push. Answers:
  - `pr da` → check, read-only: `git ls-remote --heads origin <branch>`
    shows the local `HEAD`, and `search_gitea_pull_requests` /
    `list_gitea_pull_requests` finds the open PR for `<branch>`. Record
    `pr:`, log line, then the `ABNAHME` gate. Branch not up to date or
    no PR found → say what is missing, gate `PR` stays open.
  - `ohne pr` → straight to `ABNAHME`, `pr:` stays empty.
  - `parken` → as the `park` mode.
  With `manual` commits the gate asks him to commit the staged series
  first, then push.
- **Gate `ABNAHME` (hard, always):** `## Gate` block per §4, filled from
  `handover.md` (TLDR from „In 30 Sekunden", tasks from „Für dich zu tun")
  and the Kurzfassung of each verified `ABNAHME` question in `fragen.md`.
  `gate: open` only now, after the files exist. Answers and Rückfragen to
  those questions work as in §4a/§4b (Rückfragen to a writer section go
  to the analyst).
- **On `abnehmen`:** with a `pr:`, the PR link to Jira as a comment that
  is the bare PR URL and nothing else (no text, no marker) — a Jira write
  Tobias ordered with `abnehmen`, no prompt. Without `pr:` no Jira
  write. Other Jira writes only when he asks for them in this pane;
  transitions he did not ask for stay his hand. **The PR stays open;
  merging is his.** Record `phase: done`, log line, send the done line
  to the lead (it verifies branch and PR itself). Then offer the `brain`
  skill once if something non-obvious was learned — an environment quirk
  that cost a round belongs in the work-brain note `pipeline-stolpersteine`.
- **On `abnehmen ohne-jira`:** as above without the Jira comment.
- **On `nacharbeiten`:** Nacharbeit step → `CHECKS` (same verifier) → the
  reviewers of this ticket continued with the delta (fresh single
  reviewer only when their rows are older than 60 minutes, §0) → writer
  updates `handover.md` → `PR` again (push only) → `ABNAHME` again. The
  note may point at his comments on the PR (`nacharbeiten siehe PR`):
  read them with `list_gitea_pull_request_comments` and
  `list_gitea_pull_request_reviews` and treat each unresolved one as part
  of the note. Read-only: never reply to, resolve or react to them.
- **On `parken`:** as the `park` mode.

## 4. The `## Gate` block

Overwritten at every hard stop in `state.md` (the file form below, read
by `wl <TICKET>`), printed in the chat in its **chat form** (end of this
section), and announced to the lead with the one-line notice of §0. With
questions it is drafted first (`gate: none`) and checked together with
them (§4c); only then `gate: open`, print, send. It is the chat summary of
`fragen.md`, not a second explanation: Tobias decides from it in 30
seconds or opens the file. **Plain German under the writing rules of §4a,
no class, method, table or file names and no codes above the `Details:`
line** (the `fragen.md#frage-<n>` links excepted). ≤20 lines, a blank line
between blocks, in this order:

1. **Head:** `<GATE> · <YYYY-MM-DD HH:MM>`.
2. **`TLDR:`** one sentence: the problem with its scope, and what is built
   (`SPEC`), what is done (`ABNAHME`) or what is stuck (`ESK`, `LIMIT`).
3. **Per open question**, one blank line before each: `Frage <n> ·
   <Titel>`, then its **Kurzfassung** from `fragen.md` **verbatim** (3–5
   bullets), then `→ fragen.md#frage-<n>`. Three or more questions: only
   the first three bullets each (problem, options, recommendation with its
   risk). The options are the same in chat and file: same set, same
   letters, same names. Decided questions do not appear.
4. **`Für dich zu tun:`** only what only Tobias can do (prod access, asking
   the PO, an outside party), each with when it is needed: `vor dem Bauen`
   (blocks; he answers `<n>: <Ergebnis>`, so number it after the
   questions) or `vor dem Deploy`. Never hide such a task in a
   recommendation. Omit the line when empty.
5. **`Antwort:`** one line; each answer says what it triggers.
6. **`Details:`** one line: size, branch, reviewers, hints (test DB down,
   Jira paste used), the full path of `fragen.md`. Evidence that needs more
   (error output, test names) goes into a `### Beleg` fenced block below
   the block; it stays in `state.md` and is not sent to the lead.

Example (`SPEC`):

```
## Gate
SPEC · 2026-09-30 11:05

TLDR: Die Detailansicht eines Kartenterminals soll zeigen, wie oft es seit Inbetriebnahme neu gestartet ist; nur die Anzeige, Alarme und Export bleiben wie sie sind.

Frage 1 · Zähler nach Firmware-Update zurücksetzen?
- Nach einem Firmware-Update startet ein Kartenterminal oft mehrmals neu. Offen ist, ob der neue Neustart-Zähler dann bei 0 beginnt. Betrifft nur die Detailansicht, nicht Export oder Alarme.
- A: nie zurücksetzen → Zahl über die ganze Lebensdauer · B: bei Update zurücksetzen → Zahl seit dem letzten Update, braucht ein neues Feld
- Empfehlung: A, weil das Ticket „seit Inbetriebnahme" sagt · Risiko: nach Updates springt die Zahl, das kann wie eine Störung aussehen
→ fragen.md#frage-1

Antwort: `ok` = Empfehlung übernehmen, Planung startet · `1: B` · `1: <Rückfrage>` = Antwort kommt im Chat, Gate bleibt offen · `siehe fragen.md` = deine Antworten stehen dort · `diskussion 1` = im Worker besprechen · `nein: <Notiz>` = Spec wird überarbeitet · `manual` anhängen = du committest selbst
Details: Größe M · 3 Schritte · Branch feat/RTM-4100/show-restart-counter · work-log/RED-telematik-manager/RTM-4100/fragen.md
```

Per gate:

- **`SPEC`:** only the verified fachliche questions and the tasks for
  Tobias; everything the agents decided stays out (it is in `##
  Entscheidungen` of `state.md` and `spec.md` and reaches him at
  `ABNAHME`).
- **`PR`:** TLDR = the branch is ready for his review in Gitea, in one
  sentence with the ticket's goal; no questions; `Für dich zu tun:` the
  push command and the PR (head → `develop`, title verbatim, no
  description), each on its own line in backticks; Antwort: `pr da` =
  Branch und PR prüfen, dann Abnahme · `ohne pr` = direkt zur Abnahme ·
  `parken`; Details: path of `handover.md`, commits, check line. Short:
  the content is in `handover.md` and will be in the `ABNAHME` block.
- **`ABNAHME`:** TLDR from `handover.md` „In 30 Sekunden"; the open
  `ABNAHME` questions from `fragen.md` (none → no question lines); tasks
  from „Für dich zu tun"; Antwort: `abnehmen` = PR-Link in Jira, PR bleibt
  offen · `abnehmen ohne-jira` · `nacharbeiten <Notiz>` = Nacharbeit,
  Prüfung, neuer Push, neue Abnahme (`siehe PR` = deine Kommentare im PR)
  · `parken` (with questions also `1: …`, `siehe fragen.md`); Details: PR
  URL, path of `handover.md`, commits, check line.
- **`ESK`:** TLDR = what the agents could not settle; the auditor's
  verified section in `fragen.md` as the one question; Antwort: `1: A` · `1: <eigener
  Text>` · `siehe fragen.md` · `diskussion 1`.
- **`LIMIT`:** TLDR = which criterion failed how often, in plain words;
  one question „Wie weiter?" written directly in the block (no `fragen.md`
  section and no §4c check: it is a process decision, not a product one)
  with the options that apply (`redo <phase>`, `park`, a decision that unblocks) and the
  auditor's recommendation when there is one; Details: attempts made; the
  evidence in `### Beleg` — never „läuft nicht".

**Chat form.** Claude Code renders a fenced block as monochrome code and
interprets no markdown inside it, so the gate is **never printed inside a
code fence**. Print the same content as plain markdown, same order, same
words, same option letters; the only differences are the formatting and
that the ticket id stands in the head:

```markdown
**ABNAHME · RTM-3918 · 14:16**

Die Konnektorübersicht lehnt unbekannte Werte in den Filtern … (TLDR)

**Frage 1 · Hersteller- und Umgebungsfilter mitprüfen?**
- <Kurzfassung bullet>
- A: … → … · B: … → …
- Empfehlung: A, weil … · Risiko: …
→ fragen.md#frage-1

**Für dich zu tun**
- <Aufgabe> · vor dem Deploy

**Antwort**
- `abnehmen` · PR-Link in Jira, der PR bleibt offen, mergen tust du
- `abnehmen ohne-jira`
- `nacharbeiten <Notiz>` · Nacharbeit, Prüfung, neuer Push, neue Abnahme (`siehe PR` = deine Kommentare im PR)
- `parken`

Details: PR https://git.sys.redicals.de/…/pulls/1842 · handover.md …/RTM-3918/handover.md · 1 Commit 19fb14cff · Prüfung pass, 40/40 Tests, 2 Reviewer ohne Befund
```

Rules: head line bold with gate, ticket and time; TLDR as a paragraph
without the `TLDR:` label; each question as a bold title line, its
bullets, the link; `Für dich zu tun` and `Antwort` as bold labels on
their own line with one bullet per item — every answer on its own line
with the command in backticks and, after `·`, what it triggers; Details
as the last short line. Blank lines between blocks. Only real evidence
(error output, a failing test's name list) goes into a fenced block, under
the Details line. One or two sentences of lead-in before the head line
are fine; nothing after the state line.

## 4a–4c. Questions to Tobias — `fragen-regeln.md`

The rules for `fragen.md` (§4a), Rückfragen and discussion in this pane
(§4b) and the question check with its classes (§4c) stand in
`fragen-regeln.md` next to this SKILL.md. **Read that file only when a
question is in play**: an agent returned `FRAGEN:` with a Tobias class,
a hard gate with questions is being drafted, Tobias answered or asked
back, or `discussion:` is set. A ticket without questions never needs
it. The short form you need without the file:

- Classes for Tobias: `Lücke`, `Aufwand`, `Nutzer`, `Daten` (vor dem
  Bauen), `Produkt`; `technisch` goes to the auditor.
- Before a hard gate with questions: one `plan-verifier` in **Modus:
  fragen** over the sections and the drafted gate, one round only.
- Answers to Rückfragen go into the chat, never into `fragen.md`.

## 5. Handoff to a new session

When the next phase needs a ticket worktree that does not exist yet, end
with:

```
Nächste Phase: <phase>

  /worktree <TICKET> <slug> --yes                    # Branch, Worktree, Space, Bootstrap
  wt agent <repo>/<branch-dir> -- /work <TICKET>     # Worker-Session dort
```

`/lead` does this automatically; `state.md` is what the new session reads.

## 6. Token discipline

`state.md` is the resume point — a new session reads ~50 lines, not a
transcript. This context holds briefs and result blocks only; the code
lives in the specialists' contexts. Round limits: spec check 2, plan 2,
per step 3 (M, L only), `CHECKS` 2, auditor 2 per ticket for conflicts
(plus the one planned call per spec round for technical questions and the
§4c fallback), one re-check per failed question (§4c), one verifier round
after any conflict ruling. Rückfragen have no limit; from
the second on the same question the discussion moves to this pane (§4b),
which keeps the lead's context small. The reviewers are the only parallel
fan-out.

## 7. Files this skill owns

```
work-log/<repo>/<TICKET>/
  state.md            this skill · the state machine, gates, decisions, log
  plan.md             planner · steps, DoD mapping, diagnosis, rework steps
  spec.md             analyst · the spec (short for S); technical questions and all decisions under ## Entscheidungen (auditor: its rulings; this skill: Tobias' decisions); fachliche questions only as links
  fragen.md           analyst, auditor, writer · the questions to Tobias and his answers, never deleted (§4a)
  handover.md         writer · the acceptance surface
  review.md           review / pre-review skills (untouched here)
  pruefung/           this skill via wl-write · verlauf.md (one row per agent call), befunde.md (the register), NN-<phase>-<agent>.md (result blocks verbatim)
```

`kriterien.md` (next to this SKILL.md) holds the done criteria S1–S6,
P1–P6, I1–I5, B1–B5 the verifiers check against; `fragen-regeln.md` the
rules for questions to Tobias (§4a–§4c, read on demand);
`fragen-template.md` the question layout; `state-template.md` the state
file.

Never write project source files from this session — only the implementer
does, only in the ticket worktree. Never write under `work-log/` anything
but these files. Don't commit the work-log store unless asked.
