---
name: pre-review
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

Spawn **three identical subagents in one message** (Agent tool,
`subagent_type: general-purpose`), so they run in parallel. Each is blind to
the others — do not share one reviewer's output with another. Each prompt must
contain, self-sufficiently (subagents inherit nothing from this skill):

- **The scope**: the exact git commands from step 1 so the subagent recomputes
  the same diff itself, plus the untracked-file list.
- **The rules to read first**, selected by touched paths — always the repo
  `CLAUDE.md`, plus:
  - `.claude/rules/backend/*.md` when backend files are touched (`app/`,
    `routes/`, `database/`, `config/`, `tests/`)
  - `.claude/rules/frontend/*.md` for `resources/client/**`
  - `.claude/rules/documentation.md` for `resources/docs/*.json` or
    `app/Service/Documentation/*`
- **Ticket context** (branch mode, when fetched): summary + acceptance
  criteria, with the instruction to flag gaps between diff and AC.
- **The two review dimensions**:
  1. **Rules compliance** — does the change violate a concrete rule? Every
     rule finding must name the rule file and quote the rule it breaks.
  2. **Logic errors** — correctness bugs with a concrete failure scenario:
     wrong data written or returned, broken/unreachable state transition,
     missed edge case reachable in normal operation, permission/authorization
     hole, transaction boundary or side-effect ordering problem (broadcast/
     dispatch before commit), N+1 or obvious performance trap, tests that
     assert the wrong thing or miss the changed behavior.
- **The findings discipline** (put this in the prompt verbatim):
  - Verify every finding against the actual code — open the surrounding code,
    follow the call paths. Never speculate.
  - A finding needs a realistic trigger **today**, not a chain of hypothetical
    preconditions ("if the enum ever grows…" is not a finding).
  - No style/formatting findings — Pint and PHPStan run separately.
  - Behaviour beats symmetry: "inconsistent with the sibling implementation"
    only counts when you can name the concrete consequence.
  - You are read-only. Do not modify, create, or delete any file.
- **The output format** — one block per finding:
  `file:line · [rule|logic] · [blocker|major|minor] · one-sentence claim ·
  evidence (rule quote or failure scenario) · suggested fix` — and an explicit
  "no findings" when clean.

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

With more than ~10 merged findings, fan the verification out instead: one
refuter subagent per finding, prompted to refute it against the real code and
to default to "refuted" when uncertain. Only findings that survive move on.

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
