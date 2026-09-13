# Implementation Plan: Workspace Repository Management (`mgit`)

**Branch**: `003-workspace-repo-mgmt` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/003-workspace-repo-mgmt/spec.md`

## Summary

A single dependency-free POSIX `sh` script, packaged as `mgit` (wrapped with `git`/`jq`/
`findutils`/`coreutils` on `PATH`), provides `ensure`/`status`/`inspect`. `status` is implemented
directly inside `mgit` (walking `$WORKSPACES_HOME` for `.git` dirs and reporting dirty/ahead/
behind/no-upstream) rather than shelling out to a second packaged tool, per Constitution
Principle V — v2 shipped this as two packages (`mgit` + `mgitstatus`); v3 inlines it into one.
`home/workspaces.nix`'s `home.activation` creates `~/workspaces` and an empty `mgit.json` on first
activation, matching [001's plan](../001-core-flake-shell/plan.md) for the shared module tree.

## Technical Context

Same as 001. No new flake inputs; `mgit` only needs `git`, `jq`, `findutils`, `coreutils` — all
already present via `home/tools.nix`/nixpkgs.

## Constitution Check

- Principle II (ephemeral/disposable): `~/workspaces/mgit.json` is created only if absent, never
  overwritten by activation — it's the one piece of durable, per-user state this profile owns
  outside the Nix store, by design.
- Principle V (simplicity): one packaged command, not two; recursion is deduplicated per-run via a
  simple visited-set file, no persistent cache.

No violations requiring Complexity Tracking.

## Project Structure

```text
pkgs/mgit/{default.nix,mgit}
home/workspaces.nix
```

**Structure Decision**: shares `flake.nix`/`home/` with 001; no separate project.

## Complexity Tracking

None.
