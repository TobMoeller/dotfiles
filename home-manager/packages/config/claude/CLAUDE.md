<!--
Global Claude Code instructions, version-controlled in the dotfiles repo and
symlinked to ~/.claude/CLAUDE.md via mkOutOfStoreSymlink (see
home-manager/packages/commons.nix). Applies to every project on this machine.

Edits take effect immediately — no `home-manager switch` required.
Keep this short and broadly applicable; put project-specific rules in that
project's own CLAUDE.md instead.
-->

# Global instructions

## Workflow
- Commit or push only when I explicitly ask. (Exceptions: the two brain knowledge
  stores below are auto-committed — never auto-pushed. `work-log` is not: commit
  it only when I ask. In a `/work` ticket worktree whose `state.md` says
  `commits: auto` — the default the pipeline writes when it creates the state
  file; I opt out per ticket with `/work <T> commits manual` or `manual` in a
  gate answer — that line is my explicit ask: the orchestrator commits each
  verified plan step. Pushing stays behind a prompt.)

## Knowledge vault
- Everything lives under the `~/code/knowledge/` Obsidian vault, as three separate
  git repos: `brain/` (personal), `work-brain/` (work/RED, confidential) — both
  Open Knowledge Format knowledge stores, each governed by its own `SCHEMA.md` —
  and `work-log/` (work/RED, confidential) for per-ticket task artifacts.
- **Knowledge vs artifacts:** the brain stores hold durable, recall-oriented
  knowledge. Reviews and specs are per-ticket artifacts, not knowledge — they go
  in `work-log/<repo>/<TICKET>/`, written by the `/review` and `/spec` skills.
- **Read:** before answering questions about external APIs, our domain, dev
  practices, or stored reference/snippets, grep the relevant store's `index.md` first.
- **Capture:** when we solve something non-trivial, or I state a durable fact or
  convention worth keeping, **proactively offer to file it** (don't auto-write).
  Use the `/brain` skill. Route work/RED knowledge to work-brain, personal to
  brain; if ambiguous, ask. Never store secrets or customer data. `brain/notes/`
  is a freeform human-only zone — leave it alone unless I ask. In a subagent
  there is nobody to offer to: name the candidate in your result block instead.

## Conventions
<!-- Add cross-project preferences here as they come up. -->

### Tools over bash
- Prefer the dedicated tools over shell equivalents: **Read** (not `cat`/`head`/`tail`),
  **Edit/Write** (not `sed -i`/`perl -i`/`echo >`), **Grep** (not `grep`/`rg`),
  **Glob** (not `find`/`ls` for finding files). They're faster, safer, and don't prompt.
- Run bash commands **one per call** — avoid chaining with `&&`, `;`, `|`, or `$(…)`
  substitution unless the steps are genuinely interdependent. A single allowlisted
  command (e.g. `git status`) auto-approves; a composed one almost always prompts.
- Avoid `sed`/`awk` for editing files — use the Edit tool. If you must read a slice,
  use Read with offset/limit rather than `sed -n`.

<!--
Context-degradation canary. Deliberately the last, most deeply buried rule in
this file: instruction-following decays silently in long sessions, and small
nested rules are what the model drops first — usually a turn or two before it
starts getting real work wrong. If the marker disappears, distrust the last few
answers and /clear. The Stop hook hooks/canary-check.sh watches for it; change
the marker in both places or they stop matching.
-->
## Canary
- Start every response with 🐤 — nothing before it.
