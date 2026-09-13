# Feature Specification: Java & PostgreSQL Toolchain

**Feature Branch**: `007-java-postgres-toolchain`

**Created**: 2026-09-13

**Status**: Implemented

**Input**: User description: "Pinned Java toolchain and PostgreSQL client tooling available in
every sandbox"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Java projects just work (Priority: P2)

An engineer opens a Java project in their sandbox and `java`/`mvn` are already on `PATH` at a
pinned, working version, with `JAVA_HOME` set correctly.

**Independent Test**: On an activated profile, run `java -version` and `mvn -version` and confirm
both resolve and `JAVA_HOME` points at a valid `bin/java`.

**Acceptance Scenarios**:

1. **Given** an activated profile, **When** the engineer runs a Java build, **Then** it uses the
   pinned JDK/Maven with no separate version-manager install.

---

### User Story 2 - Postgres credentials handled the same safe way (Priority: P2)

An engineer connects to a Postgres database using `psql` with credentials resolved from a
documented, permission-checked file, and can list/test/inspect those credentials with a small CLI
rather than hand-editing connection strings.

**Independent Test**: Populate the credentials file with one entry per its documented format; run
the CLI's `test` subcommand and confirm it validates the connection.

**Acceptance Scenarios**:

1. **Given** a populated Postgres credentials file, **When** the engineer runs `psql` against a
   named entry, **Then** the connection is made without the password ever appearing in shell
   history or an ambient environment variable.

### Edge Cases

- What happens on first activation when no Postgres credentials file exists yet? A mode-600
  template must be created without overwriting any existing file.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The base profile MUST install a pinned JDK and Maven, and set `JAVA_HOME`
  accordingly.
- **FR-002**: The base profile MUST declaratively manage a `psql` configuration file (prompt,
  history, pager, and shortcut settings).
- **FR-003**: The base profile MUST create a Postgres credentials file (mode 600) on first
  activation if absent, using a documented id/description/boundary comment-header format, and
  MUST NOT overwrite an existing one.
- **FR-004**: A small CLI MUST provide `list`, `test`, `env`, `url`, and `psql` subcommands
  operating on that credentials file's entries.
- **FR-005**: The environment health check (spec 004) MUST report the Java toolchain's presence
  and version, and the Postgres credentials file's existence/permissions.
- **FR-006**: Documentation MUST explain how to override the pinned JDK/Maven version and the
  credentials file's format with runnable examples.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A Java build and a Postgres connection both work immediately after activation with
  no manual toolchain install.
- **SC-002**: No Postgres password appears in shell history or an ambient environment variable
  during normal use of the CLI.

## Assumptions

- One pinned JDK/Maven version is provided by default; multi-JDK version switching is out of
  scope.
