# Implementation Plan: Core Flake + Home-Manager Base

**Branch**: `001-core-flake-shell` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-core-flake-shell/spec.md`

## Summary

A `flake.nix` at the repo root exposes `homeConfigurations.default` (fixed identity, for CI/
`nix flake check`) and `homeConfigurations.current` (the real caller's `$USER`/`$HOME`, `--impure`,
for real installs). The shared module set lives under `home/` and configures bash, oh-my-posh,
direnv, and git declaratively; a small pinned tool set ships alongside it. This plan covers specs
001-005 together where they share structure (one flake, one `home/` module tree, one `pkgs/`
aggregate) since splitting them into unrelated projects would be artificial.

## Technical Context

**Language/Version**: Nix (flakes) + POSIX `sh` for packaged scripts.

**Primary Dependencies**: `nixpkgs` (`nixos-24.11`), `home-manager` (`release-24.11`). No other
flake inputs (Constitution: minimal input set).

**Storage**: N/A (dotfiles + a local, git-ignored credentials file; see spec 002's plan).

**Testing**: `nix flake check` (evaluates and builds `checks.<system>.default`, the activation
package); manual activation in a scratch account for `doctor` verification.

**Target Platform**: Linux (incl. WSL2) and macOS, `x86_64`/`aarch64`.

**Project Type**: Nix flake / home-manager module + a small set of packaged shell CLIs.

**Performance Goals**: N/A (provisioning tool, not a runtime service).

**Constraints**: No Homebrew/pkgx/eget/mise/SDKMAN!/chezmoi (Constitution "Toolchain"); secrets
never ambient (Constitution Principle III, detailed in spec 002's plan).

**Scale/Scope**: Single engineer's sandbox, replicated identically across N machines/containers.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Principle I (lockfile-pinned): satisfied by `flake.lock` covering both inputs.
- Principle II (ephemeral/disposable): `home-manager switch`/`activate` from a clean checkout is
  the only supported path; no imperative one-off steps.
- Principle V (simplicity): no per-persona profiles, no fish, no sops-by-default — those are
  either dropped (personas: not requested by any core spec) or made opt-in (sops: spec 002 FR-006).

No violations requiring Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-core-flake-shell/
├── plan.md      # this file
└── spec.md
```

(No research.md/data-model.md/contracts — this is infrastructure, not an API; a quickstart lives
in the repository README instead of a per-spec doc, since one README serves all five core specs.)

### Source Code (repository root)

```text
flake.nix                     # inputs, forAllSystems, homeConfigurations, packages, checks
home/
├── default.nix                # imports + programs.home-manager.enable
├── shell.nix                  # bash, oh-my-posh, zoxide, fzf (specs 001)
├── git.nix                    # git identity + delta + aliases (specs 001, 002)
├── direnv.nix                 # direnv + nix-direnv (specs 001)
├── tools.nix                  # pinned everyday CLI tools (specs 001)
├── workspaces.nix              # ~/workspaces + ws-repos.json activation (specs 003)
└── secrets.nix                 # opt-in sops-based workspacesHost.secrets (specs 002)
themes/oh-my-posh/coach.omp.json
pkgs/
├── default.nix                 # aggregate: ws-repos, doctor, workspaces-host-update
├── ws-repos/                   # specs 003
├── doctor/                      # specs 004
├── workspaces-host-update/      # specs 002
└── init-firewall/               # specs 005
oci/                             # specs 005
credentials.example              # specs 002
.github/workflows/ci.yml         # specs 004
install.sh                       # top-level installer (specs 001+002)
README.md
```

**Structure Decision**: One flake, one `home/` module tree, one `pkgs/` aggregate — the five core
specs are separable *specs* (each independently reviewable) but not separable Nix projects; they
compose into one home-manager profile, matching how v2 was actually built and verified.

## Complexity Tracking

None.
