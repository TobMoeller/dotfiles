---
name: pre-review
model: opus
effort: high
description: Self-review changes before they leave the machine — either the open working-tree changes (pre-commit) or the whole ticket branch (pre-push). Fans out three independent reviewer subagents that each check the same diff against the repo's .claude/rules and for logic errors, merges and adversarially verifies their findings in the main context, then fixes the confirmed ones directly (never commits). Use when the user wants their own open changes checked before committing (e.g. "review my open changes", "pre-commit review", "check this before I commit") or the whole branch checked before pushing/handing to a reviewer (e.g. "pre-review the branch", "pre-review RTM-1234", "check everything before I push").
argument-hint: "[branch | RTM-XXXX] (default: open changes)"
allowed-tools: Agent Read Grep Glob Edit Write Bash(git status:*) Bash(git diff:*) Bash(git log:*) Bash(git show:*) Bash(git merge-base:*) Bash(git rev-parse:*) Bash(git ls-files:*) Bash(vendor/bin/phpunit:*) Bash(vendor/bin/phpstan:*) Bash(vendor/bin/pint:*) mcp__devtools-mcp__read_jira_issue
---

# Pre-review (red / work)

Catch rule violations and logic errors in your own changes before a colleague
sees them. Three independent reviewers → merge → adversarial verification →
direct fix. This skill edits files but **never commits, pushes, or posts
anything** — commits are managed by the user.

## 1. Determine the scope

Two modes — pick from the argument / phrasing:

- **Open changes** (default, no argument): everything not yet committed.
  - Inventory: `git status --porcelain` (staged, unstaged, untracked)
  - Diff: `git diff HEAD`
  - Untracked files are in scope — list them explicitly; they must be read in
    full, they have no diff.
- **Branch mode** (`branch`, a ticket number, or the user says "before I
  push" / "before the review"): the whole ticket.
  - Base: `git merge-base origin/develop HEAD`
  - Diff: `git diff <base>` — this includes committed **and** still-open
    changes, which is exactly what would end up in the push. Plus untracked
    files as above.
  - If a ticket number is given (or derivable from the branch name) and the
    Jira MCP is reachable, pull the ticket (`read_jira_issue`) and extract
    description + acceptance criteria as reviewer context. **One attempt,
    non-blocking** — skip silently if unreachable.

If the scope is empty, say so and stop.

## 2. Deterministic checks first

Run before spawning reviewers — anything a tool catches is not worth reviewer
attention:

- `vendor/bin/phpstan analyse` (full project — it's fast)
- `vendor/bin/pint --test` (full project)
- Targeted tests only, **never the full suite**: map the changed classes to
  their test files and run `vendor/bin/phpunit path/to/Test.php` or
  `vendor/bin/phpunit --filter <TestName>`. The test DB is always up — no
  docker checks needed.
- Frontend files: no vitest on this host (broken rolldown binding) — frontend
  changes get static review only.

A failure caused by the diff is a finding (fixed in step 6). Pre-existing
failures untouched by the diff: report them, do not fix them.

## 3. Fan out three independent reviewers

Spawn **three `reviewer` subagents in one message** (Agent tool,
`subagent_type: reviewer`; the profile in `~/.claude/agents/reviewer.md`
carries the rules to read, the two review dimensions, the findings
discipline and the output format), so they run in parallel. Each is blind
to the others — do not share one reviewer's output with another. Brief each
with only what it cannot know:

- **The scope**: the exact git commands from step 1 so the subagent
  recomputes the same diff itself, plus the untracked-file list.
- **Ticket context** (branch mode, when fetched): summary + acceptance
  criteria, with the instruction to flag gaps between diff and AC.

## 4. Merge and dedupe

Merge the three lists. Same spot + same claim → one finding; keep the reviewer
count (1/3 … 3/3) as **information only**. Never drop a finding because only
one reviewer saw it — unique catches are the entire point of the redundancy.
The count feeds verification effort, not survival.

## 5. Adversarial verification

For each merged finding, actively try to refute it before touching anything:

- Open the cited code and follow the call path yourself.
- A **rule** finding dies when the rule file doesn't actually say that, the
  code doesn't actually violate it, or an explicit exception in the rules
  covers the case.
- A **logic** finding dies when the failure scenario cannot actually occur —
  guarded elsewhere on the call path, unreachable input, or an existing test
  proves the behavior.

With more than ~10 merged findings, fan the verification out instead: a
`step-verifier` subagent in „Modus: widerlegen" per batch of findings (at
most 5 in parallel), each returning a `WIDERLEGT: ja|nein · Beleg` line per
finding. Only findings that survive move on.

## 6. Fix directly

Fix the confirmed findings without a confirmation round:

- Smallest correct fix, following the repo rules and surrounding style.
- After all fixes: rerun PHPStan, Pint, and the affected tests.
- **Surface instead of fixing** when the resolution is a judgment call (design
  tradeoff, naming, scope question), would change behavior beyond the ticket's
  intent, or concerns pre-existing code outside the diff. These go to the user
  as open items — deciding them is not this skill's job.
- **Never commit.** Leave everything in the working tree.

## 7. Report

Final summary in German, ordered by file:

- Scope + result of the deterministic checks (one line each).
- **Gefixt:** per finding one line — `file:line`, what was wrong (rule name or
  failure scenario), what the fix was.
- **Verworfen:** one compact line total ("N Findings verworfen, z. B. …") —
  no detail walls for refuted findings.
- **Offen:** the judgment-call items with a one-line recommendation each.
- Close with the check status after fixing (PHPStan/Pint/tests green or not).
