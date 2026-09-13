# Implementation Plan: Workspace Repository Management (`ws-repos`)

**Branch**: `003-workspace-repo-mgmt` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/003-workspace-repo-mgmt/spec.md`

## Summary

A single dependency-free POSIX `sh` script, packaged as `ws-repos` (wrapped with `git`/`jq`/
`findutils`/`coreutils` on `PATH`), provides `ensure`/`status`/`inspect` — a port of
[strategy-coach/workspaces](https://github.com/strategy-coach/workspaces)' `mgit.ts`/
`ws-ensure.ts` "mGit" pattern, named differently from upstream (and from v2's own `mgit`) only to
avoid colliding with unrelated third-party tools also called `mgit`; the `*.mgit.code-workspace`
file suffix it recognizes is kept exactly as upstream hardcodes it, for interop. `status` is
implemented directly inside `ws-repos` (walking `$WORKSPACES_HOME` for `.git` dirs) rather than
shelling out to a second packaged tool, per Constitution Principle V — v2 shipped this as two
packages (`mgit` + `mgitstatus`); v3 inlines it into one, and this revision brings its status
output back up to upstream's own fidelity (stash count, stuck `index.lock`, untracked-vs-dirty).
`home/workspaces.nix`'s `home.activation` creates `~/workspaces` and an empty `ws-repos.json` on
first activation, matching [001's plan](../001-core-flake-shell/plan.md) for the shared module
tree.

## Technical Context

Same as 001. No new flake inputs; `ws-repos` only needs `git`, `jq`, `findutils`, `coreutils`,
`gnugrep`, `gnused` — all already present via `home/tools.nix`/nixpkgs. `*.code-workspace`
comment-tolerance (spec FR-008) is a `sed`-based best-effort filter, not a new dependency.

## Constitution Check

- Principle II (ephemeral/disposable): `~/workspaces/ws-repos.json` is created only if absent,
  never overwritten by activation — it's the one piece of durable, per-user state this profile
  owns outside the Nix store, by design.
- Principle V (simplicity): one packaged command, not two; recursion is deduplicated per-run via a
  simple visited-set file, no persistent cache; JSONC tolerance is a pragmatic filter rather than
  pulling in a real parser (which would mean a runtime dependency, e.g. Deno, that this
  POSIX-shell port deliberately avoids).

No violations requiring Complexity Tracking.

## Project Structure

```text
pkgs/ws-repos/{default.nix,ws-repos}
home/workspaces.nix
```

**Structure Decision**: shares `flake.nix`/`home/` with 001; no separate project.

## Complexity Tracking

None.
