# Implementation Plan: Environment Health Check & Rollback

**Branch**: `004-doctor-rollback` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/004-doctor-rollback/spec.md`

## Summary

A single unwrapped POSIX `sh` script, packaged as `doctor`, prints one PASS/WARN/FAIL line per
check (Nix/flakes, home-manager, shell/prompt/direnv, git identity, credentials file, `ws-repos`/
workspace layout, every tool this profile installs, `docker` optional) and exits non-zero only on
a FAIL. It is deliberately *not* wrapped with a fixed `PATH` (unlike every other `pkgs/*` tool
here), since its entire job is to observe the caller's real environment. Rollback is documented
(README), not re-implemented: home-manager's own generation list + that generation's `activate`
script. A GitHub Actions workflow runs `nix flake check` and `doctor` against a real activation on
every push/PR. See [001's plan](../001-core-flake-shell/plan.md) for the shared architecture.

## Technical Context

Same as 001. `doctor` has no build-time dependency on the other packages it checks for — it only
shells out to `command -v` at runtime.

## Constitution Check

- Principle II (ephemeral/disposable): rollback uses home-manager's built-in generations, not a
  bespoke snapshot mechanism — nothing new to keep reproducible.
- Principle V (simplicity): `doctor` checks only what specs 001-003/005 actually install; no
  speculative checks for backlog-tier tooling (those checks are added alongside their own spec's
  implementation, per the constitution's spec-tiering policy).

No violations requiring Complexity Tracking.

## Project Structure

```text
pkgs/doctor/{default.nix,doctor}
.github/workflows/ci.yml
```

**Structure Decision**: shares `flake.nix`/`home/` with 001; no separate project.

## Complexity Tracking

None.
