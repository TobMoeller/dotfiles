# Claude skills

Personal [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills),
version-controlled here and linked into `~/.claude/skills` by
`home-manager/packages/claude-skills.nix`.

## Layout

Skills are organised into **groups**; each group is a directory of skills, and
each skill is its own directory containing a `SKILL.md`:

```
skills/
  common/        # linked on every machine
    explain/SKILL.md
    fix/SKILL.md
    review/SKILL.md
    ticket/SKILL.md
  red/           # linked on the red (work) machine only
    explain/SKILL.md   # work variant — overrides common/explain on red
    comment/SKILL.md   # voice + post/paste rules for anything written to Gitea/Jira
    lead/SKILL.md      # coordinator: day plan → one worker session per ticket (wt agent) → watch gates
    work/              # ticket pipeline: assess (orchestrator analyses) → build loop (implementer → refactorer → logik review) → full review ×2 → accept
      SKILL.md         #   the orchestrating analyst: analyses, briefs, judges, merges, fixes minors, hands over
      ticket-template.md   # layout of ticket.md (Hergang outside-in, DoD, Scope, Fragen, Entscheidungen)
      state-template.md    # the state file, copied per ticket
      kriterien.md     #   rules A (analysis), L (loop), V (full review), severities, Schreibregeln
    day/SKILL.md       # morning overview + evening Slack status, reads wl / the state files
    tickets/SKILL.md   # router to the team's ticket skills in ai-tooling (story, epic, bug, review, spec)
    worktree/SKILL.md  # ticket → branch name (repo rule) → `wt add` (space + docker/env bootstrap)
    worktree-move/SKILL.md # branch worktree ⇄ main checkout via `wt main` / `wt back`, session hand-over by resume
```

A skill directory may hold supporting files next to `SKILL.md` (templates,
reference tables); the skill refers to them by their path next to itself.

## The ticket pipeline (`/lead`, `/work`, `/day`) and the agents

Three layers, each with its own context:

```
/lead   (coordinator session, anywhere)        talks to Tobias, starts/watches workers
  └─ worker session per ticket (its worktree)  `wt agent <repo>/<branch-dir> -- /work RTM-1234`
       └─ /work (the orchestrating analyst)     analyses the ticket itself (ticket.md), briefs, judges, merges, commits, hands over
            ├─ implementer    loop station 1       → builds the whole ticket, functionality + one test per DoD item, raw
            ├─ refactorer     loop station 2       → reads all rules, restructures and renames directly, keeps tests green, escalates larger existing-code refactorings
            ├─ reviewer       loop station 3 (Modus logik, read-only, runs tests) · full review ×2 (Modus voll) · /review, /pre-review (Modus pr)
            └─ (no planner, verifier, writer or auditor: the orchestrator holds the agents to kriterien.md itself)
```

**The flow** (since 2026-10-07, on trial; no size classes): the
orchestrator reads ticket and subsystem and writes `ticket.md` with the
Hergang from the outside in (trigger → classes in order → the spot), the
DoD verbatim, scope, entry points, questions for Tobias. Questions and
Umbau hints go straight to Tobias at `FRAGEN`, otherwise no stop. The
build loop runs implementer → refactorer → logik reviewer in their own
sessions until no `major`/`blocker` is open (max three rounds), one commit
per round. Then two independent full reviewers; the orchestrator merges
and refutes their findings itself, fixes `minor` ones directly and sends
`major` ones back into the loop (max two full-review rounds). Then it
writes `handover.md`, Tobias pushes at `PR` and decides at `ABNAHME`.

Agent profiles live in `../agents/<group>/<name>.md` and are linked into
`~/.claude/agents` by `home-manager/packages/claude-agents.nix`
(`claudeAgentGroups`, same override rule as skills). All agents run on
Opus (`model: opus`, `effort` per profile); the lead
session (`wt lead` passes `--model fable`) on Fable. The
session model itself comes from `permissions/red.json` (`"model": "opus"`,
merged into settings.json), because a skill's own `model:` only lasts one
turn. Every specialist ends with an `ERGEBNIS:` block the orchestrator
parses.

`/work RTM-1234` persists where it is in
`~/code/knowledge/work-log/<repo>/<TICKET>/state.md` (phase, gate, round,
agent ids, log) and `ticket.md` (the analysis, questions with answers,
decisions), so any session resumes from disk. **Gates are files, not
dialogs:** a hard gate writes a `## Gate` block into `state.md` and ends
the turn; the answer comes back as `/work RTM-1234 <Antwort>`, typed in
the worker or relayed by `/lead`. Hard gates exist only at `FRAGEN` (only
when there are questions, an Umbau hint or a blocking task for Tobias),
`ESK` (the refactorer escalates an existing-code refactoring, or a round
limit is exhausted), `PR` (Tobias pushes and opens the PR himself; not
part of the acceptance) and `ABNAHME` (`handover.md` and the PR are the
review surface). The orchestrator is Tobias' conversation partner at every
gate: it answers Rückfragen itself from its analysis. The commit mode is
no gate: the pipeline writes `commits: auto` into `state.md` when it
creates it, and Tobias opts a ticket out with `/work RTM-1234 commits
manual` or `manual` in a gate answer. Rework of any kind (review
findings, Tobias' `nacharbeiten` note) is one loop round plus a full
review. The whole flow is written up for humans in `../PIPELINE.md`
(linked to `~/.claude/PIPELINE.md`). Implementation requires the ticket's
worktree, created with the `wt` script (docker/env bootstrap, `.wt-ready`
marker) — never a bare `git worktree add`.

`/lead` runs once a day in its own herdr space (`wt lead`, cwd = the
work-log store), starts one worker session per ticket with `wt agent`
(herdr agent underneath: own pane, `herdr agent start/prompt/wait`; refuses
while the worker is working or blocked), and then talks to the workers via
`SendMessage`: a worker sends its `## Gate` block and its done line to the
name in `work-log/.lead-session`, the lead relays Tobias' answer as
`/work <TICKET> <Antwort>` to the worker's `session_name`. It verifies
„done" against `git log`, `git ls-remote` and Gitea, keeps the day's note
(`work-log/daily/<date>.md`, `## Verlauf`), and falls back to `wl` and
herdr's idle/working/blocked states when no message comes. Permission
prompts in a worker are answered in its space, never from `/lead`.

`/day` reads `wl`, `gitday` (see `scripts/gitday`), Jira and Gitea: in the
morning an overview with a suggestion, in the evening the Slack status draft
plus an archive note under `work-log/daily/`.

### Permissions for autonomy (red host)

`permissions/red.json` sets `defaultMode: auto` and the session model,
allows the read-only tools, `git add`, checks in worktrees and `wt agent`,
and puts every push, PR, Jira or Gitea write, worktree teardown, branch
deletion and direct `herdr agent prompt` under `ask` so those prompts are
the gates. Its `autoMode` block tells the classifier about Gitea, Jira, the
worktrees and the work-log store. Three hooks make the boundaries
mechanical: `hooks/bash-guard.sh` (PreToolUse) denies `sudo`, force pushes,
`migrate:fresh`/`db:wipe` and asks on any spelling of `git push` and on
`compose down` with volumes; `hooks/commit-guard.sh`
(PreToolUse) allows a single plain `git commit` in a ticket worktree only
when its `state.md` says `commits: auto` (the default the pipeline writes)
and denies it on `manual` (Tobias' per-ticket opt-out);
`hooks/worktree-allow.sh` (PermissionRequest) answers prompts for routine
checks inside a worktree, including the test DB: `wt testdb` is the one
command agents use for it (starts the worktree's database + redis, waits,
runs the testing-env migrate + seed; `/work` runs it when the build
starts, `wt add` deliberately does not). `bash-guard` is wired in `settings.json`; the
other two still need their entries there (see the recap in the session
that added them).

### Relation to the team's `ai-tooling` repo

`~/code/RED-telematik-manager/ai-tooling` holds the team's Claude skills as
project-level skills. Our pipeline **bypasses its implementation track**
(dev-feature-plan / dev-feature-implement / implementierung) on purpose. The
four we use are linked by name into `~/.claude/skills` through
`claudeExternalSkills` in `red-tobias.nix` (live symlinks into the
checkout, so the team's updates apply without a switch):
`feature-story-erstellen`, `bug-ticket-erstellen`, `epic-erstellen`,
`feature-doku-pflegen`. They are self-contained (shared sections inlined by
the team's convention, no file under ai-tooling's `tickets/` needed), so a
`/work` worker invokes them directly to create follow-up tickets. `/tickets`
routes to them and lists what is deliberately not linked. The Jira ticket
is the only handover between the two worlds.

## How groups are selected

Each host picks its groups via `claudeSkillGroups` (see `commons.nix` for the
default and the per-host `*.nix` files):

```nix
claudeSkillGroups = [ "common" "red" ];   # common + red, red wins on name clash
```

Groups are linked in order and **a later group overrides an earlier one** when
two skills share the same directory name — that's how `red/explain` replaces
`common/explain` on the work machine while every other common skill stays.

## Adding / editing skills

- **Editing** an existing `SKILL.md` applies immediately (out-of-store symlink) —
  no `home-manager switch` needed.
- **Adding or removing** a skill directory needs a `home-manager switch` to
  create or drop its symlink.
- To add a new group (e.g. `mbp`), create the directory with at least one skill
  and add it to that host's `claudeSkillGroups`.
