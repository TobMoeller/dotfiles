# Working on this repository

- Read README.md and docs/architecture.md before structural changes.
- The legacy checkout and playground branch are references, not templates to copy wholesale.
- Use explicit imports of flake-parts modules; features are selected per host/user.
- Keep native program configuration next to its feature. Use direct checkout symlinks where interactive editing is intentional.
- Keep host account details and identities out of shared features. Never commit credentials or private keys.
- Preserve system.stateVersion and home.stateVersion unless a migration explicitly requires changing them.
- Validate changes by evaluating the NixOS toplevel and running flake checks. Report separately what was evaluated, built, and activated.
- Do not activate system changes or push to GitHub without user authorization.
- Use explicit working directories: this session may still be rooted in dotfiles-legacy.
