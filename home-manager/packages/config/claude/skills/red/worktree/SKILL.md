---
name: worktree
description: Create the branch and the isolated worktree (own herdr space or tmux session, docker/env/port bootstrap via the wt script) for a Jira ticket — reads the ticket, derives the branch name from the repo's branch-naming rule (feat|fix/RTM-XXXX/<slug>), reuses an existing branch for the ticket if a colleague already pushed one, shows a dry run, then runs `wt add`. Use when the user wants a worktree or branch for a ticket (e.g. "worktree für RTM-1234", "leg den Branch für RTM-1234 an", "/worktree RTM-1234 external-firmware-upload").
argument-hint: "<RTM-XXXX> [slug] [--base <ref>] [--yes]"
model: opus
effort: low
allowed-tools: Read Grep Glob Edit Bash(wt add:*) Bash(wt ls) Bash(git branch:*) Bash(git for-each-ref:*) Bash(git rev-parse:*) Bash(git ls-remote:*) Bash(git worktree list:*) mcp__devtools-mcp__read_jira_issue
---

# Worktree for a ticket (red / work)

Script and skill split the job: the skill knows the ticket and the naming rule,
`wt` knows sessions, docker, env files and ports. The skill never runs
`git worktree add` or `git branch` itself — everything that creates state goes
through `wt add`, so a manual `wt add` and a skill-created worktree are
indistinguishable.

## 1. Resolve the repo

Run `git rev-parse --path-format=absolute --git-common-dir` (one call);
`main` is its parent directory. Not inside a git repo → the red machine has
one repo with worktrees; use `~/code/RED-telematik-manager/RED-telematik-manager`
and say so in the output.

## 2. Read the ticket

`read_jira_issue <TICKET>` → summary and issue type. Jira MCP is flaky: one
attempt, then ask for title and type. Ticket id from the argument, upper-case,
`RTM-\d+`.

## 3. Derive the branch name

Rule: `.claude/rules/branch-naming.md` in the repo →
`<type>/<TICKET>/<slug>`.

- **type:** issue type Bug → `fix`, everything else → `feat`. The team's
  history also has `chore/` for housekeeping tickets; use it only when the
  user says so.
- **slug:** from the argument if given, else from the summary: English,
  kebab-case, 3–5 words, verb-first where natural, no ticket id, no
  German filler. Look at recent branches for tone:
  `git for-each-ref --sort=-committerdate --count=20 --format='%(refname:short)' refs/remotes`.
- **Existing branch for the ticket?**
  `git branch -a --list '*<TICKET>*'` (after `wt add`'s fetch it is fresh;
  for the check run `git ls-remote --heads origin '*<TICKET>*'`). If one
  exists, **prefer it** (the colleague's or your own earlier branch) and say
  why; `wt add` will track it. Two candidates → ask.
- **Existing worktree?** `wt ls` lists `repo/branch-dir`. If the ticket
  already has one, don't create a second — `wt add <main> <branch>` simply
  focuses it.

## 4. Dry run, then create

```bash
wt add <main> <branch> --dry-run
```

Show its four lines (repo, branch + how it comes into being, worktree path,
session). Unless `--yes` was passed, ask one question: „So anlegen?" with
the branch name editable. A `--base <ref>` from the argument is passed
through; default is `origin/develop` (wt resolves it).

Then:

```bash
wt add <main> <branch> [--base <ref>] [--no-focus]
```

`wt add` fetches, creates the branch and the worktree, opens the herdr space
(or tmux session) and starts the bootstrap **inside that space**: env files
and ports from `tools/setup-worktree.sh`, reflink copy of `vendor/` and
`node_modules/`, and finally a `.wt-ready` marker (`.wt-failed` on error)
that `/work` checks before implementing. The bootstrap output lives there,
not here. In herdr the new space gets focus unless `--no-focus` is passed;
pass it when `--yes` was given (the `/lead` case), so the coordinator
session keeps the screen.

A failed fetch (`wt: fetch failed, using local refs`) is a warning, not an
error: the branch is still created from the local `origin/develop`. Report it
so the user can `git fetch` later. A `die` from wt (invalid branch name,
missing base ref, not a repo) is the result — report it verbatim, don't retry
with a guessed name.

## 5. Hand over

If `~/code/knowledge/work-log/<repo>/<TICKET>/state.md` exists, set its
`branch:` and `worktree:` frontmatter fields (Edit) and add a log line
`worktree · Branch <branch> angelegt, Space <session>`. Don't create a state
file — that is `/work`'s job.

Close with three lines:

```
Branch <branch> · Worktree <repo>/<branch-dir> · Space <session> (bootstrapping)
Worker starten:  wt agent <repo>/<branch-dir> -- /work <TICKET>
```

## Stay in scope

Read-only against Jira. No commits, no pushes, no file changes in any checkout.
Never remove or recreate a worktree — `wt rm` is the user's hand.
