# Feature Specification: Advanced Local Nix-Level Overrides

**Feature Branch**: `013-local-nix-overrides`

**Created**: 2026-09-13

**Status**: Draft (Backlog — not yet implemented; see constitution's spec-tiering policy)

**Input**: User description: "An advanced local.nix override file for personal Nix-level
customization (identity, secrets, persona tweaks) outside the repository, picked up impurely by
the current profile"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Customize my profile without forking the repo (Priority: P3)

An engineer wants to add a Nix-level tweak specific to their own machine (an extra package, a
`workspacesHost.secrets` declaration, an identity override) without maintaining a fork or a local
patch that `workspaces-host-update`'s `git pull` would conflict with.

**Independent Test**: Create a local override file declaring one extra package; activate the
`current` profile; confirm the package is present, and confirm `nix flake check` (which never
touches this file) is unaffected.

**Acceptance Scenarios**:

1. **Given** a local override file exists outside the repository, **When** the engineer activates
   the `current` profile, **Then** its contents are merged into that activation.
2. **Given** no local override file exists, **When** any profile (including `current`) is
   activated, **Then** activation proceeds exactly as if this feature didn't exist.
3. **Given** a local override file exists, **When** `nix flake check` runs (pure evaluation), **Then**
   the check is completely unaffected by it — this mechanism only ever applies to the impure
   `current` profile.

### Edge Cases

- What happens when the override file has a Nix syntax error? Activating `current` should fail
  with a clear Nix evaluation error pointing at that file, not a confusing failure elsewhere in
  the module tree.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `current` profile MUST import a fixed, well-known path outside the repository
  (e.g. `~/.config/workspaces-host/local.nix`) if it exists, and MUST NOT fail or change behavior
  if it doesn't.
- **FR-002**: Every other profile (`default`, any fixed-identity profile `nix flake check`
  builds) MUST remain completely unaffected by this file's presence or absence, so pure
  evaluation stays pure.
- **FR-003**: Options this file commonly overrides (at minimum git identity) MUST be declared
  with `lib.mkDefault` in their owning module, so the override file can win without a Nix
  "conflicting definition" error.
- **FR-004**: A tracked `local.nix.example` at the repository root MUST demonstrate the format.
- **FR-005**: The environment health check (spec 004) MUST report whether this file exists,
  purely informationally (its absence is never a WARN or FAIL — it's an advanced, optional path).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An engineer can add a personal Nix-level customization without forking the
  repository or ever conflicting with `git pull`.
- **SC-002**: `nix flake check` behavior is provably identical with and without this file
  present.

## Assumptions

- This is a power-user escape hatch, not the primary customization path — the primary path for
  identity and secrets remains the plain credentials file (spec 002).
