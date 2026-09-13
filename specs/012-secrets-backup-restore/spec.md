# Feature Specification: Secrets & Sensitive-Directory Backup/Restore

**Feature Branch**: `012-secrets-backup-restore`

**Created**: 2026-09-13

**Status**: Draft (Backlog — not yet implemented; see constitution's spec-tiering policy)

**Input**: User description: "sensitivectl tool to back up and restore named local directories to
and from an rclone remote"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Back up a sensitive local directory to my own remote (Priority: P3)

An engineer keeps a local directory of genuinely sensitive material (personal notes, exported
keys, anything they don't want only living on one disk) and wants to sync it to a remote storage
provider they already use, without this repository hardcoding which provider.

**Independent Test**: Configure one profile pointing at a local directory and a test remote; run
backup, then restore into a fresh directory; confirm contents match.

**Acceptance Scenarios**:

1. **Given** a named profile with a local path and a remote, **When** the engineer runs the
   backup command, **Then** the remote ends up matching the local directory.
2. **Given** a remote populated by a prior backup, **When** the engineer runs the restore
   command on a machine that never had the local directory, **Then** the local directory is
   recreated from the remote.

### Edge Cases

- What happens when no profiles are configured yet? `list` must say so clearly rather than
  erroring, and `backup`/`restore` must refuse with a clear message naming the missing config
  path.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The flake MUST provide a `sensitivectl` command with `list`, `backup <profile>`,
  and `restore <profile>` subcommands, driven by a JSON config at a documented default path
  (overridable via an environment variable).
- **FR-002**: `sensitivectl backup`/`restore` MUST work against any `rclone`-supported remote
  type — the tool itself MUST NOT hardcode a specific provider.
- **FR-003**: `sensitivectl backup`/`restore` MUST pass through any arguments after `--` directly
  to the underlying `rclone sync` invocation (e.g. `--dry-run`, `--exclude`).
- **FR-004**: The environment health check (spec 004) MUST report `sensitivectl` on `PATH`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An engineer can back up and later fully restore a configured directory using only
  `sensitivectl` and their own already-configured `rclone` remote, with no manual `rclone`
  invocation.

## Assumptions

- `rclone` itself is configured with the target remote's credentials out-of-band (`rclone
  config`), the same as Constitution Principle III's "decryption key material is a deliberate,
  separate step" applies to any credential this repository doesn't manage.
- This is distinct from spec 002's `workspacesHost.secrets` (field-level encryption of one
  credential at rest): this spec is whole-directory sync to a remote, for material broader than a
  single token.
