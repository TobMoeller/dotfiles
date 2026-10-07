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
# Same mechanism as ./claude-skills.nix, for the specialists the /work and
# /lead skills delegate to (analyst, planner, implementer, verifiers, reviewer,
# writer) and the auditor they escalate to.

let
  live = "${config.home.homeDirectory}/code/tobmoeller/dotfiles/home-manager/packages/config/claude/agents";
  repo = ./config/claude/agents;

  # group -> { "<name>.md" = "<live target path>"; ... }
  groupAgents = group:
    lib.mapAttrs
      (file: _: "${live}/${group}/${file}")
      (lib.filterAttrs (file: type: type == "regular" && lib.hasSuffix ".md" file)
        (builtins.readDir (repo + "/${group}")));
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
