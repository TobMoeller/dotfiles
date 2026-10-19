# Development environment

Add the project's runtimes and tools to `devShells.default.packages` in
`flake.nix`. This template supplies Git and supports Linux and macOS on
x86_64/aarch64. Additional packages may have platform-specific restrictions.

```bash
# In a Git repository, Nix must see newly created files first.
git add flake.nix .envrc .gitignore
nix flake lock
git add flake.lock
nix develop
# Or run one command:
nix develop --command git --version
```

`nix develop` opens Bash by default. Use `nix develop --command zsh` if zsh
is already installed and you want your usual interactive shell. Exit to leave
the environment. No system rebuild is required.

With direnv and nix-direnv installed and hooked into your shell, review
`.envrc` and run `direnv allow` once in this directory. It then loads the
environment into your current shell when you enter, and unloads it when you
leave. Without direnv, `nix develop` works independently.

Commit `flake.nix`, `flake.lock` and optionally `.envrc`; keep `.direnv/`
untracked. The project's lockfile is independent from the machine's system
configuration. Update this project's packages with `nix flake update nixpkgs`.
Application dependencies still belong in their native manifests/lockfiles
(e.g. package.json/package-lock.json or pyproject.toml/uv.lock).
