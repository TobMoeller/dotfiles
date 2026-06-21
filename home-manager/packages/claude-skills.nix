{ config, lib, ... }:

# Links personal Claude Code skills into ~/.claude/skills, one out-of-store
# symlink per skill so edits to a SKILL.md apply immediately (no switch needed;
# adding/removing a skill folder does need a switch to create/drop its link).
#
# Skills live in groups under packages/config/claude/skills/<group>/<skill>/.
# Each host selects which groups to link via `claudeSkillGroups`. Later groups
# override earlier ones on a name collision, so list shared groups first:
#   claudeSkillGroups = [ "common" "red" ];   # red's skills win over common's

let
  # Live repo path (out-of-store symlink target) — edits here apply instantly.
  live = "${config.home.homeDirectory}/code/tobmoeller/dotfiles/home-manager/packages/config/claude/skills";
  # Store path used only to enumerate skills at eval time (flake-pure-eval safe).
  repo = ./config/claude/skills;

  # group -> { <skill-name> = "<live target path>"; ... }
  groupSkills = group:
    lib.mapAttrs
      (name: _: "${live}/${group}/${name}")
      (lib.filterAttrs (_: type: type == "directory")
        (builtins.readDir (repo + "/${group}")));
in {
  options.claudeSkillGroups = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ "common" ];
    description = "Skill groups to link into ~/.claude/skills; later groups override earlier on name clash.";
  };

  config.home.file =
    let
      # Fold groups in order so a later group replaces an earlier skill of the
      # same name, leaving exactly one symlink per name (the override).
      merged = lib.foldl' (acc: g: acc // groupSkills g) { } config.claudeSkillGroups;
    in
    lib.mapAttrs'
      (name: target: lib.nameValuePair ".claude/skills/${name}" {
        source = config.lib.file.mkOutOfStoreSymlink target;
      })
      merged;
}
