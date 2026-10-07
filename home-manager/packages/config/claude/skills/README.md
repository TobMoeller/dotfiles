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
    work/              # ticket pipeline: assess → spec → plan → implement → verify → review → accept
      SKILL.md         #   orchestrator: delegates every phase to the agents below, state on disk
      state-template.md#   supporting file, copied per ticket
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
       └─ /work (orchestrator)                 reads/writes state.md, delegates, commits verified steps
            ├─ analyst        assess + spec       → spec.md (always) / Diagnose, DoD, real questions
            ├─ planner        plan                → plan.md
            ├─ plan-verifier  soft gate           → pass / fail / unsicher
            ├─ implementer    one plan step       → uncommitted diff + checks
            ├─ step-verifier  schritt | branch (CHECKS) | widerlegen → pass / fail / unsicher · WIDERLEGT
            ├─ reviewer ×2/3  review              → findings (also used by /pre-review, /review)
            ├─ writer         handover.md, PR/Jira text
            └─ auditor (Fable, common group)     → ruling on conflicts, max 2 per ticket
```

Agent profiles live in `../agents/<group>/<name>.md` and are linked into
`~/.claude/agents` by `home-manager/packages/claude-agents.nix`
(`claudeAgentGroups`, same override rule as skills). All specialists run on
Opus (`model: opus`, `effort` per profile); the auditor and the lead
session (`wt lead` passes `--model fable`) on Fable. The
session model itself comes from `permissions/red.json` (`"model": "opus"`,
merged into settings.json), because a skill's own `model:` only lasts one
turn. Every specialist ends with an `ERGEBNIS:` block the orchestrator
parses.

`/work RTM-1234` persists where it is in
`~/code/knowledge/work-log/<repo>/<TICKET>/state.md` (phase, gate, step,
round, diff base, decisions, log), so any session resumes from disk.
**Gates are files, not dialogs:** a hard gate writes a `## Gate` block into
`state.md` and ends the turn; the answer comes back as `/work RTM-1234
<Antwort>`, typed in the worker or relayed by `/lead`. Hard gates exist only
at `SPEC` (only when the spec has product questions for Tobias), `PR`
(Tobias pushes and opens the PR himself; not part of the acceptance) and
`ABNAHME` (`handover.md` and the PR are the review surface), plus `ESK`/`LIMIT` when the pipeline
cannot settle something itself. The commit mode is no gate: the pipeline
writes `commits: auto` into `state.md` when it creates it, and Tobias opts a
ticket out with `/work RTM-1234 commits manual` or `manual` in a gate answer. Everything else is a verified loop:
plan-verifier (2 rounds), step-verifier per step for sizes M and L (3
rounds), whole-branch `CHECKS` (2 rounds), two reviewers (three for L)
whose findings a step-verifier in „widerlegen" mode refutes. Rework of any
kind (`CHECKS` fail, review findings, Tobias' `nacharbeiten` note) becomes
an appended plan step and runs through the same loop. The whole flow is
written up for humans in `../PIPELINE.md` (linked to `~/.claude/PIPELINE.md`). The implementer leaves each step uncommitted; after the
verifier's pass the orchestrator stages it and, with `commits: auto` (the
default), commits it. A verifier's `unsicher` or a repeated conflict goes to the
auditor (one more verifier round after its ruling); its `Tobias` answer is
a hard stop. Implementation requires the ticket's worktree, created with
the `wt` script (docker/env bootstrap, `.wt-ready` marker) — never a bare
`git worktree add`.

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
checks inside a worktree, including the test-DB bootstrap
(`docker compose up -d [services]`, `php artisan migrate --seed --env=testing`). `bash-guard` is wired in `settings.json`; the
other two still need their entries there (see the recap in the session
that added them).

### Relation to the team's `ai-tooling` repo

`~/code/RED-telematik-manager/ai-tooling` holds the team's Claude skills as
project-level skills. Our pipeline **bypasses its implementation track**
(dev-feature-plan / dev-feature-implement / implementierung) on purpose. What we
do use from it is **ticket creation and maintenance**: `feature-story-erstellen`,
`epic-erstellen`, `bug-ticket-erstellen`, `feature-ticket-review`,
`feature-spezifizieren`, `subbugs-abarbeiten`. They are not linked here because
they depend on ai-tooling's own `CLAUDE.md` (`tickets/<KEY>/` convention) and
MCP alias — `/tickets` routes to them and explains how to run them in that
checkout. The Jira ticket is the only handover between the two worlds.

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
