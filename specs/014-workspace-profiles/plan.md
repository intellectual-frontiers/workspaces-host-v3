# Implementation Plan: Workspace Profiles (Personas)

**Branch**: `014-workspace-profiles` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

## Summary

`flake.nix` gains a `personaModules` attrset mapping persona name → `home/profiles/<name>.nix`,
mirrored into `homeConfigurations.<persona>` (fixed identity, `x86_64-linux`, for `nix flake
check`) and `homeConfigurations.current-<persona>` (impure, real identity) — the exact mechanism
v2 used, restored verbatim since it was only ever removed for simplicity, not because it was
wrong.

## Technical Context

Same as spec 001's plan. No new flake inputs; every persona package is plain nixpkgs.

## Constitution Check

- Principle V (simplicity): personas stay strictly additive — the base profile's behavior is
  provably unchanged whether or not any persona exists, so this doesn't compromise the "simplest
  design that satisfies the spec today" for anyone who doesn't opt in.

No violations requiring Complexity Tracking.

## Project Structure

```text
flake.nix                      # personaModules / personaConfigurations / currentPersonaConfigurations
home/profiles/backend.nix
home/profiles/data.nix
home/profiles/mobile.nix
home/profiles/agent-ops.nix
```

**Structure Decision**: shares `flake.nix`/`home/` with the core specs; each persona module is
one small, self-contained file.

## Complexity Tracking

None.
