# Implementation Plan: Git Hooks with Lefthook

**Branch**: `016-git-hooks-lefthook` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

## Summary

`pkgs.lefthook` added to `home/tools.nix`; a tracked `templates/lefthook.yml.example` documents
a starter config (mirroring how `templates/agent-harness/` already documents its own template
set). README gains a short adoption section. No custom Nix module needed — Lefthook is
self-contained and reads its own `lefthook.yml` per project.

## Technical Context

Same as spec 001's plan. No new flake inputs.

## Constitution Check

- Principle I (reproducible by lockfile): the *tool* is pinned by this flake; the example config
  it drives is deliberately per-project, not something this repo can or should pin globally.

No violations requiring Complexity Tracking.

## Project Structure

```text
home/tools.nix                     # + lefthook
templates/lefthook.yml.example
```

**Structure Decision**: shares `flake.nix`/`home/` with the core specs; the template follows the
same convention as `templates/agent-harness/`.

## Complexity Tracking

None.
