---
name: worktree-move
description: Move a ticket branch between its worktree and the main checkout so the user can live-test it (or park it again), and hand the running Claude session over to the other checkout — checks both checkouts are clean, shows a dry run, runs `wt main` / `wt back`, then tells the user how to resume this session there. Use when the user wants to test a worktree branch in the main checkout, continue a session in the main tree, or move a branch back into its worktree (e.g. "zieh den Branch in den Haupt-Ordner", "ich will das live testen", "session in den main tree verschieben", "/worktree-move back").
argument-hint: "[main|back] [--yes]"
model: opus
effort: low
disable-model-invocation: true
allowed-tools: Read Edit Bash(wt main:*) Bash(wt back:*) Bash(wt ls) Bash(git status:*) Bash(git branch:*) Bash(git rev-parse:*) Bash(git worktree list:*) Bash(git log:*)
---

# Move a branch between worktree and main checkout (red / work)

Same split as `worktree`: `wt` changes state, the skill decides whether it is
safe and hands the session over. The skill never runs `git switch`,
`git worktree remove` or `docker compose` itself.

## 1. Direction

- `main` (default when run inside a worktree): the worktree's branch moves
  into the main checkout, the worktree **and its docker stack incl. volumes**
  are removed.
- `back` (default when run in the main checkout on a non-default branch): the
  main checkout returns to the default branch, `wt add` recreates the
  worktree for the branch (fresh bootstrap, fresh test DB).

Main checkout: the parent directory of what `git rev-parse
--path-format=absolute --git-common-dir` prints (one call).

## 2. Preconditions

Check both checkouts with `git status --short` before anything else.

- **Uncommitted or untracked changes in the checkout the branch leaves:** stop.
  Never commit on your own; ask whether and with which message to commit
  (commit messages and granularity are the user's call). A staged index is
  the user's review baseline — never add, reset or amend around it.
- **Tracked changes in the target checkout:** stop and name the files.
  Untracked files there (e.g. `log.csv`) are fine; git refuses on its own if
  one would be overwritten.
- **Worktree on a detached HEAD** (branch already moved by hand): `wt main`
  refuses. If the main checkout already has the branch, only the worktree is
  left over — that is `wt rm`, the user's hand.

## 3. Note the session id

This session's id is `${CLAUDE_SESSION_ID}` (Claude Code substitutes it
when the skill loads). Never copy, move or edit a transcript — a
hand-copied duplicate is reported as not found instead of resumed.

If `~/code/knowledge/work-log/<repo>/<TICKET>/state.md` exists, write the open
questions and the next step into it, set `worktree:` to the target checkout
so `wl` and `/lead` look in the right place, and add the log line
`worktree-move · <branch> → <main|worktree>`. Don't create a state file —
that is `/work`'s job.

## 4. Dry run, then move

```bash
wt main --dry-run            # or: wt back <main> --dry-run
```

Show its lines. Unless `--yes` was passed, ask one question: „So umziehen?"
— for `main` name explicitly that the worktree's docker stack and test DB
are deleted. Then:

```bash
wt main --keep-session       # or: wt back <main>
```

`--keep-session` keeps the herdr space / tmux session this Claude runs in
alive, so the result gets back to you. After `wt main` the current working
directory no longer exists — run no further commands in it.

A `die` from wt is the result: report it verbatim, don't work around it.

## 5. Hand over

Close with:

```
<branch> ist jetzt in <target> ausgecheckt.
Weiter in <target>:   claude --resume <session-id>
Danach den alten Space schließen.
```

Why this works for `main`: resume re-enters a session's original worktree;
when that worktree no longer exists, the session continues in the directory
it is launched from
(https://code.claude.com/docs/en/worktrees.md#resume-a-worktree-session).
For `back` the recreated worktree has the original path again, so a session
that started there resumes inside it. A session that started in the main
checkout is not a worktree session — resuming it from the new worktree is not
documented; say so and suggest a fresh session with `/work <TICKET>` instead.

For live-testing in the main checkout, list what the branch still needs
without running it: pending migrations (`php artisan migrate:status
--pending`, read-only), a changed `composer.lock` or `package-lock.json`
against the previous branch. Running `migrate` on the dev DB is the user's
hand.

## Stay in scope

No commits, no pushes, no transcript files touched. Never run `wt rm`, and
never run `migrate` against the dev database.
