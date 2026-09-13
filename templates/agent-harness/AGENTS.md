# Agent Instructions

This project is provisioned by [workspaces-host-v3](https://github.com/intellectual-frontiers/workspaces-host-v3):
its dev environment, CLI toolset, and shell configuration come from a
`flake.nix` + home-manager module, not from manually-installed packages.

## Environment

- `nix develop` (if this project has its own `flake.nix`) or the ambient
  workspaces-host profile provides the toolchain - don't `apt install` or
  `brew install` anything; add it to the relevant Nix expression instead
  so it stays reproducible for every agent/human that opens this repo.
- Secrets are never exported as ambient environment variables. If a task
  needs a credential that isn't already scoped in, say so rather than
  hunting for one in the shell environment.

## Build / test / lint

<!-- Fill this in per-project: the exact commands an agent should run
     before considering a change complete, e.g.:
     - Build:  `<command>`
     - Test:   `<command>`
     - Lint:   `<command>`
-->

## Conventions

- Small, independent changes over big-bang rewrites.
- Match existing code style; don't reformat unrelated code in the same
  change.
- See `.claude/skills/` for any repo-specific skills, and `.mcp.json` for
  this project's declared MCP servers.
