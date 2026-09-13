# Implementation Plan: Zero-Trust Networking Clients

**Branch**: `017-zero-trust-networking` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

## Summary

`pkgs.tailscale` and `pkgs.nebula` added to `home/tools.nix` as plain client packages — no
`systemd`/`launchd` service module, no auto-start, no key material provisioned. `doctor` reports
both as WARN-tier (optional, like `docker`). README documents the two human-in-the-loop steps
(Tailscale's `tailscale up` login; a Nebula CA-issued certificate) this spec deliberately does
not automate.

## Technical Context

Same as spec 001's plan. No new flake inputs.

## Constitution Check

- Principle III (secrets/trust material never provisioned by this repo): joining a Tailnet or a
  Nebula mesh requires trust material (an account login, a CA-issued cert) this flake cannot and
  should not generate or store — the same boundary the credentials file and `workspacesHost.secrets`
  already draw for API keys.
- Principle IV (container/cloud-harness parity): both clients build into the OCI images the same
  as any other `home.packages` entry — no special-casing needed, though actually creating a TUN
  device inside a container depends on that container runtime's own capabilities, outside this
  flake's control.

No violations requiring Complexity Tracking.

## Project Structure

```text
home/tools.nix     # + tailscale, nebula
pkgs/doctor/doctor  # + WARN-tier checks
```

**Structure Decision**: shares `flake.nix`/`home/` with the core specs; no separate project, no
service module.

## Complexity Tracking

None.
