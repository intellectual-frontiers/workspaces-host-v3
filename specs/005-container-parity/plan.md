# Implementation Plan: Container & Cloud-Harness Parity

**Branch**: `005-container-parity` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/005-container-parity/spec.md`

## Summary

`packages.<system>.oci-image` is a `dockerTools.buildLayeredImage` built directly from
`homeConfigurations.<system>.config.home.packages` and its generated dotfiles (bash rc/profile,
git config, oh-my-posh config, nix-direnv integration) — the exact same evaluation 001's host
profile produces, plus `cacert`/`dockerTools.fakeNss` for a usable minimal container.
`packages.<system>.oci-image-sandboxed` (Linux only, since `iptables`/`ipset` are
`meta.badPlatforms` on Darwin) layers a non-root `agent` user and an `init-firewall` +
`setpriv`-drop-privileges entrypoint on top of the same closure. See
[001's plan](../001-core-flake-shell/plan.md) for the shared flake/module architecture.

## Technical Context

Same as 001, plus `dockerTools` (nixpkgs, no extra flake input) for image building and
`iptables`/`ipset`/`util-linux` (Linux only) for the sandboxed variant.

## Constitution Check

- Principle IV (container/cloud-harness parity): both images are built from the same
  `homeConfigurations` evaluation as the host profile — no separately maintained package list or
  hand-written Dockerfile.
- Principle V (simplicity): the sandboxed variant reuses `init-firewall` verbatim rather than a
  bespoke per-image firewall script.

No violations requiring Complexity Tracking.

## Project Structure

```text
oci/{default.nix,sandboxed.nix,sandboxed-entrypoint.sh}
pkgs/init-firewall/{default.nix,init-firewall}
```

**Structure Decision**: shares `flake.nix`/`home/` with 001; no separate project.

## Complexity Tracking

None.
