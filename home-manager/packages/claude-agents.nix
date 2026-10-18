{ config, lib, ... }:

# Links personal Claude Code subagent profiles into ~/.claude/agents, one
# out-of-store symlink per agent file so edits apply immediately (no switch
# needed; adding/removing an agent file does need a switch to create/drop its
# link).
#
# Agents live in groups under packages/config/claude/agents/<group>/<name>.md.
# Each host selects which groups to link via `claudeAgentGroups`. Later groups
# override earlier ones on a name collision, so list shared groups first:
#   claudeAgentGroups = [ "common" "red" ];   # red's agents win over common's
#
# Same mechanism as ./claude-skills.nix, for the agents the /work skill
# delegates to (implementer, refactorer, reviewer; the reviewer also serves
# /review and /pre-review).

let
  live = "${config.home.homeDirectory}/code/tobmoeller/dotfiles/home-manager/packages/config/claude/agents";
  repo = ./config/claude/agents;

  # group -> { "<name>.md" = "<live target path>"; ... }
  # A group whose directory does not exist (git drops empty directories, so a
  # group whose last agent was removed vanishes from the flake source) links
  # nothing instead of failing the evaluation.
  groupAgents = group:
    let dir = repo + "/${group}"; in
    if !builtins.pathExists dir then { } else
    lib.mapAttrs
      (file: _: "${live}/${group}/${file}")
      (lib.filterAttrs (file: type: type == "regular" && lib.hasSuffix ".md" file)
        (builtins.readDir dir));
in {
  options.claudeAgentGroups = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ "common" ];
    description = "Agent groups to link into ~/.claude/agents; later groups override earlier on name clash.";
  };

  config.home.file =
    let
      merged = lib.foldl' (acc: g: acc // groupAgents g) { } config.claudeAgentGroups;
    in
    lib.mapAttrs'
      (file: target: lib.nameValuePair ".claude/agents/${file}" {
        source = config.lib.file.mkOutOfStoreSymlink target;
      })
      merged;
}
