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
- Commit or push only when I explicitly ask. (Exception: the second-brain stores
  below are auto-committed — never auto-pushed.)

## Second brain
- Knowledge stores in Open Knowledge Format live at `~/code/brain` (personal) and
  `~/code/work-brain` (work/RED, confidential). Each has a `SCHEMA.md` that governs it.
- **Read:** before answering questions about external APIs, our domain, dev
  practices, or stored reference/snippets, grep the relevant store's `index.md` first.
- **Capture:** when we solve something non-trivial, or I state a durable fact or
  convention worth keeping, **proactively offer to file it** (don't auto-write).
  Use the `/brain` skill. Route work/RED knowledge to work-brain, personal to
  brain; if ambiguous, ask. Never store secrets or customer data.

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
