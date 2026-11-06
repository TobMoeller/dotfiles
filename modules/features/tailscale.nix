{
  # Tailscale client: reaches subnet routes published in the tailnet (e.g.
  # the home network via a subnet router). No exit node, no subnet router,
  # no Tailscale SSH on this side. Login is interactive; see docs/tailscale.md.
  flake.modules.nixos.tailscale = {
    services.tailscale = {
      enable = true;
      # Loosens reverse-path filtering so replies from accepted subnet
      # routes are not dropped.
      useRoutingFeatures = "client";
    };
  };

  # `homenet on|off|status` wraps up/down with the right flags.
  flake.modules.homeManager.tailscale = { config, ... }: {
    home.file.".local/bin/homenet".source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.repositoryPath}/scripts/homenet";
  };
}
