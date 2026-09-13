# Implementation Plan: Additional CLI Tools

**Branch**: `015-additional-cli-tools` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

## Summary

Five plain nixpkgs packages (`gopass`, `wget`, `rclone`, `git-chglog`, `deno`) added to
`home/tools.nix`; two aliases and an SSH-agent-autostart block added to `home/shell.nix`'s
`programs.bash`. No new packaging work — everything here already exists in nixpkgs 24.11
(verified directly against this flake's pinned input before writing any code).

## Technical Context

Same as spec 001's plan. No new flake inputs.

## Constitution Check

- Principle V (simplicity): no wrapper module needed — these are plain packages/aliases, added
  where spec 001's `home/tools.nix`/`home/shell.nix` already live.

No violations requiring Complexity Tracking.

## Project Structure

```text
home/tools.nix     # + gopass, wget, rclone, git-chglog, deno
home/shell.nix     # + deno-run/deno-test/cdp aliases, SSH agent autostart
```

**Structure Decision**: shares `flake.nix`/`home/` with the core specs; no separate project.

## Complexity Tracking

None.
