{ config, pkgs, lib, ... }:

# Generates ~/.claude/settings.json from a shared base plus any host-selected
# overlays. Unlike the per-skill out-of-store symlinks, this file is
# *generated*, so edits to the base settings.json or to an overlay only take
# effect after `home-manager switch`.
#
# Overlays live in packages/config/claude/permissions/<group>.json and may
# carry three top-level keys, all optional:
#
#   permissions  allow / deny / ask arrays (unioned onto the base, deduped,
#                base entries first) and scalar keys such as defaultMode
#                (overlay wins)
#   autoMode     environment / allow / soft_deny / hard_deny prose rule arrays
#                for the auto-mode classifier (unioned the same way; a key
#                that no file sets is left out entirely, because an empty
#                array without "$defaults" would discard the built-in rules)
#   env          environment variables (overlay wins per key)
#   model        the session model alias/id (overlay wins); skills' own
#                `model:` only lasts one turn, so the session default is what
#                keeps /lead, /work and the workers on the intended model
#
# Each host opts in via `claudePermissionGroups`; the base is always included:
#   claudePermissionGroups = [ "red" ];   # adds red's devtools allows, ask
#                                         # gates and auto-mode environment

let
  base = lib.importJSON ./config/claude/settings.json;

  overlays = map
    (group: lib.importJSON (./config/claude/permissions + "/${group}.json"))
    config.claudePermissionGroups;

  # Merge two attrsets: scalars from b win; the named list keys are unioned
  # (deduped, a first) but only when at least one side defines them.
  mergeLists = keys: a: b:
    (a // b) // lib.listToAttrs (map
      (k: lib.nameValuePair k (lib.unique ((a.${k} or [ ]) ++ (b.${k} or [ ]))))
      (lib.filter (k: (a ? ${k}) || (b ? ${k})) keys));

  mergePermissions = mergeLists [ "allow" "deny" "ask" ];
  mergeAutoMode = mergeLists [ "environment" "allow" "soft_deny" "hard_deny" ];

  permissions = lib.foldl'
    (acc: o: mergePermissions acc (o.permissions or { }))
    (base.permissions or { })
    overlays;

  autoMode = lib.foldl'
    (acc: o: mergeAutoMode acc (o.autoMode or { }))
    (base.autoMode or { })
    overlays;

  env = lib.foldl' (acc: o: acc // (o.env or { })) (base.env or { }) overlays;

  model = lib.foldl' (acc: o: if o ? model then o.model else acc) (base.model or null) overlays;

  settings = base // { inherit permissions; }
    // lib.optionalAttrs (autoMode != { }) { inherit autoMode; }
    // lib.optionalAttrs (env != { }) { inherit env; }
    // lib.optionalAttrs (model != null) { inherit model; };
in {
  options.claudePermissionGroups = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Overlay groups merged into ~/.claude/settings.json (permissions, autoMode and env; arrays unioned onto the base).";
  };

  config.home.file.".claude/settings.json".source =
    (pkgs.formats.json { }).generate "claude-settings.json" settings;
}
