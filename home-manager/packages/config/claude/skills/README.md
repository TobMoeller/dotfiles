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
```

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
