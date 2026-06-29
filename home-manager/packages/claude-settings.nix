{ config, pkgs, lib, ... }:

# Generates ~/.claude/settings.json from a shared base plus any host-selected
# permission overlays. Unlike the per-skill out-of-store symlinks, this file is
# *generated*, so edits to the base settings.json or to an overlay only take
# effect after `home-manager switch`.
#
# Overlays live in packages/config/claude/permissions/<group>.json and may carry
# `allow`, `deny`, and/or `ask` arrays. Each host opts in via
# `claudePermissionGroups`; the base is always included, and overlay arrays are
# unioned onto the base (deduplicated, base entries first):
#   claudePermissionGroups = [ "red" ];   # adds red's read-only devtools allows

let
  base = lib.importJSON ./config/claude/settings.json;
  basePerms = base.permissions or { };

  # An overlay's permission arrays, with missing keys defaulting to empty.
  overlayPerms = group:
    let p = lib.importJSON (./config/claude/permissions + "/${group}.json");
    in {
      allow = p.allow or [ ];
      deny = p.deny or [ ];
      ask = p.ask or [ ];
    };

  # Union the base allow/deny/ask with each selected overlay, deduping.
  mergedPerms =
    let
      combined = lib.foldl'
        (acc: group:
          let p = overlayPerms group; in {
            allow = acc.allow ++ p.allow;
            deny = acc.deny ++ p.deny;
            ask = acc.ask ++ p.ask;
          })
        {
          allow = basePerms.allow or [ ];
          deny = basePerms.deny or [ ];
          ask = basePerms.ask or [ ];
        }
        config.claudePermissionGroups;
    in
    {
      allow = lib.unique combined.allow;
      deny = lib.unique combined.deny;
      ask = lib.unique combined.ask;
    };

  settings = base // {
    permissions = basePerms // mergedPerms;
  };
in {
  options.claudePermissionGroups = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Permission overlay groups merged into ~/.claude/settings.json (allow/deny/ask arrays unioned onto the base).";
  };

  config.home.file.".claude/settings.json".source =
    (pkgs.formats.json { }).generate "claude-settings.json" settings;
}
