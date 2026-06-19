# Claude skills

Personal [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills),
version-controlled in the dotfiles repo and symlinked to `~/.claude/skills` via
`mkOutOfStoreSymlink` (see `home-manager/packages/commons.nix`).

Each skill lives in its own subdirectory containing a `SKILL.md`:

```
skills/
  my-skill/
    SKILL.md
```

Because the directory is an out-of-store symlink, adding or editing a skill here
takes effect immediately — no `home-manager switch` required.
