# Feature Specification: Devcontainer Support

**Feature Branch**: `021-devcontainer-support`

**Created**: 2026-10-03

**Status**: Implemented

**Input**: User description: "Make workspaces-host-v3 usable as an 'instant' devcontainer on any
OS that supports containers - docs, or a repo file, or both?"

## Background

Spec 020 made the base profile's exact closure pullable as a public OCI image
(`ghcr.io/intellectual-frontiers/workspaces-host-v3`). The devcontainer spec (the convention VS
Code, GitHub Codespaces, and the standalone `devcontainer` CLI all implement) is the one piece
that turns "there's a public image" into "opening this repository instantly gives you a working
environment": a `.devcontainer/devcontainer.json` file is auto-detected by every one of those
tools, with no further setup. This is a repository file, not only documentation - the convention
has no other way to be discovered.

The image's own `Cmd` (`oci/default.nix`) is a root login bash shell with `WorkingDir=/root`, and
defines no non-root user. Devcontainer tooling instead expects the repository to be bind-mounted
in and `cd`'d into, so `devcontainer.json` sets `remoteUser`/`workspaceFolder` explicitly rather
than changing the OCI image definition itself - the image stays single-purpose, and the
devcontainer-specific shape lives in the one file that's actually devcontainer-specific.

`postCreateCommand` runs `doctor` through a login shell (`bash -lc 'doctor || true'`), not a bare
command: home-manager's shell config - `PATH`, aliases, `WORKSPACES_HOST_REPO` itself -
only loads through the `.bash_profile` -> `.bashrc` chain a login shell runs, the same reason
`container-ci.adoc` already documents `docker run -it ... bash -l`, not a bare `docker run ...
bash`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open in container, instantly (Priority: P2)

An engineer (or an AI coding agent operating a devcontainer-aware tool) opens this repository in
VS Code, a Codespace, or runs the `devcontainer` CLI directly against it, and gets a fully
provisioned shell with no Nix install and no local build step.

**Why this priority**: This is the concrete, auto-detected mechanism that makes spec 020's public
image actually "instant" rather than merely pullable by hand.

**Independent Test**: With only Docker installed (no Nix), run `devcontainer up --workspace-folder
.` against a clone of this repository and confirm it succeeds and `doctor` runs during
`postCreateCommand`.

**Acceptance Scenarios**:

1. **Given** a clone of this repository and a container runtime, **When** an engineer opens it in
   a devcontainer-aware tool, **Then** the published image (spec 020) is pulled - no local Nix
   build - and `postCreateCommand` runs `doctor` against the resulting shell.
2. **Given** the same setup, **When** the container starts, **Then** the repository's own files
   are available inside it at `/workspaces/<repo-name>` (the devcontainer tool's own default
   workspace mount), ready to edit.

### Edge Cases

- What happens on an OS or container runtime that can't run a Linux container directly (older
  Docker Desktop configurations, some CI sandboxes without a running daemon)? Outside this spec's
  control - the same constraint applies to every other container workflow this repository
  documents (`docker run`, the `oci-image`/`oci-image-sandboxed` builds), not something unique to
  the devcontainer config.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST provide `.devcontainer/devcontainer.json` referencing the
  published image (`ghcr.io/intellectual-frontiers/workspaces-host-v3:latest`, spec 020) via its
  `image` property - no local `Dockerfile`/build step.
- **FR-002**: `devcontainer.json` MUST set `remoteUser` and `workspaceFolder` explicitly, since
  the published image defines neither a non-root user nor a devcontainer-shaped working directory
  on its own.
- **FR-003**: `devcontainer.json` MUST run `doctor` via `postCreateCommand` through a login shell
  (`bash -lc`), so a user opening the container sees an immediate, authoritative health check
  without a manual step.
- **FR-004**: README and the documentation book's `container-ci` chapter MUST document this as an
  explicit alternative to `docker run`/`nix build`, in language both a human and an AI agent
  reading either file would act on directly.

### Key Entities

- **`.devcontainer/devcontainer.json`**: the repository file that makes this instant - the one
  artifact devcontainer-aware tooling auto-detects, as opposed to documentation a reader has to
  find and follow by hand.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `devcontainer up --workspace-folder .` against a clone of this repository succeeds
  with no Nix installed, using only the published image.
- **SC-002**: Opening this repository in a devcontainer-aware editor requires zero configuration
  beyond "reopen in container" - no prompts, no manual image selection.

## Assumptions

- Only this repository's own devcontainer config is in scope. Documenting how another project can
  copy this same `image` reference into its own `devcontainer.json` to get this environment
  belongs in the documentation book (`container-ci` chapter), not as a second repository file -
  there is nothing to add to a project that isn't this one.
