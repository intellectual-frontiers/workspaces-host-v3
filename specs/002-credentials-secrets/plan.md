# Implementation Plan: Credentials & Secrets Handling

**Branch**: `002-credentials-secrets` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/002-credentials-secrets/spec.md`

## Summary

`credentials.example` documents a plain `KEY=value` template. A packaged `workspaces-host-update`
script bootstraps the real file at `~/.config/workspaces-host/credentials` (mode 600), parses it
without sourcing it as shell, writes `GIT_NAME`/`GIT_EMAIL` into a git-config `[include]` file
`home/git.nix` references, and writes every other key into
`$XDG_STATE_HOME/workspaces-host/secrets/env/<KEY>` (mode 600) — never an ambient shell export. An
opt-in `home/secrets.nix` module (`workspacesHost.secrets`) covers the advanced sops-encrypted
path (FR-006), decrypting at activation time into the same secrets directory.

See [001's plan](../001-core-flake-shell/plan.md) for the shared flake/module architecture this
spec plugs into (`home/git.nix`'s `lib.mkDefault` identity, `home/secrets.nix`).

## Technical Context

Same as 001 (Nix + POSIX `sh`, no extra flake inputs except `sops`/`age` packages already in
nixpkgs — no new flake input needed, since sops-nix's *module* isn't used, only the plain `sops`
CLI at activation time, matching v2's verified approach).

## Constitution Check

- Principle III (secrets never ambient/unscoped): the credentials parser never `source`s the file;
  every non-identity value lands in a private, mode-600 path, never exported shell-wide.
- Principle V (simplicity): the plain-file path is the default and only mandatory mechanism; sops
  is opt-in and adds no cost when unused (`lib.mkIf (cfg != {})`).

No violations requiring Complexity Tracking.

## Project Structure

```text
credentials.example
pkgs/workspaces-host-update/{default.nix,workspaces-host-update}
home/git.nix            # lib.mkDefault identity + `[include]` of the generated file
home/secrets.nix        # opt-in workspacesHost.secrets option
```

**Structure Decision**: shares `flake.nix`/`home/` with 001; no separate project.

## Complexity Tracking

None.
