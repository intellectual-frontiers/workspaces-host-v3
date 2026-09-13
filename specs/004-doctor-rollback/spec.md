# Feature Specification: Environment Health Check & Rollback

**Feature Branch**: `004-doctor-rollback`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "doctor command that checks the environment is actually working end
to end, plus instant rollback to the previous generation when a change goes wrong"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Know immediately if something is wrong (Priority: P1)

After activating or updating their environment, an engineer runs one command and gets a
PASS/WARN/FAIL line for every part of the setup: the shell, git identity, credentials, workspace
management, and every installed tool.

**Why this priority**: Without a single source of truth for "is this actually working," engineers
(especially ones new to Linux) have no way to self-diagnose problems, which undermines the whole
premise of a shared, reliable environment.

**Independent Test**: Run the health check against a freshly activated environment with a blank
git email; confirm it reports PASS for the shell/tools and WARN (not FAIL) for the unset email.

**Acceptance Scenarios**:

1. **Given** a fully configured environment, **When** the engineer runs the health check, **Then**
   every check reports PASS and the command exits zero.
2. **Given** an environment with one genuinely broken piece (e.g. a tool missing from `PATH`),
   **When** the engineer runs the health check, **Then** that check reports FAIL, every other
   check still runs, and the command exits non-zero.
3. **Given** an environment with an optional, unconfigured piece (e.g. no git email set yet),
   **When** the engineer runs the health check, **Then** that check reports WARN, not FAIL, and
   the command still exits zero if nothing else failed.

---

### User Story 2 - Undo a bad update instantly (Priority: P1)

An update to the environment breaks something. The engineer rolls back to the previous working
generation without reinstalling anything from scratch.

**Why this priority**: Confidence to pull updates depends on knowing a bad one is trivially
reversible (Principle II: ephemeral and disposable, never a one-way door).

**Independent Test**: Activate generation A, activate a deliberately broken generation B, then
roll back; confirm the environment matches generation A again.

**Acceptance Scenarios**:

1. **Given** two home-manager generations exist, **When** the engineer lists generations and
   re-activates the earlier one, **Then** the environment returns to that generation's exact
   state with no manual cleanup.

### Edge Cases

- What happens when only one generation exists (nothing to roll back to)? The rollback
  documentation/tooling must make this state clear rather than failing confusingly.
- What happens when a check depends on an optional tool (e.g. `docker`) that the engineer never
  installs? That check must WARN, not FAIL, since it is optional infrastructure for a subset of
  features (container parity, spec 005).
- What happens when the health check itself is run with a non-default `PATH` (e.g. from a
  minimal CI shell)? It must observe the caller's actual environment, not a `PATH` fixed at
  packaging time, so it reports the caller's true state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A `doctor` command MUST be installed on `PATH` by the base profile, checking at
  minimum: Nix and flakes enabled; home-manager on `PATH`; the shell, prompt, and direnv
  integration from spec 001; whether the caller's actual login shell (via the real `/etc/passwd`
  entry, not `$SHELL`) is one of this flake's own pinned shells - bash, or fish if the `fish`
  persona (spec 014) is active - not just installed, and WARN (not FAIL) only when it's neither.
  A login-shell path matching one of these two exactly is necessary but not sufficient: this
  check MUST also confirm the binary named there still actually exists and is executable (`chsh`
  writes a fixed path into `/etc/passwd` and never revisits it, so a persona deactivated or
  rebuilt away after `chsh` leaves a dangling path that a plain string comparison would wrongly
  report as PASS - verified directly against that exact scenario, not assumed) and WARN, naming
  `ws-persona activate`/`workspaces-host-update` as the fix, when it doesn't; git on `PATH` and
  identity configured (WARN, not FAIL, if unset); every tool this repository installs; `ws-repos` and
  the workspace layout from spec 003; the credentials file's existence and permissions from spec
  002; GitHub/GitLab authentication for `gh`/`glab` (spec 002 FR-008), counting either an existing
  login or a configured token as authenticated; and `docker` on `PATH` (WARN only — optional, for
  spec 005's container images).
- **FR-001a**: `doctor` MUST also check, all as WARN rather than FAIL since none of them indicate
  a broken *provisioning*, only an environment worth double-checking: SSH key existence and
  `~/.ssh`/key file permissions; whether `$HOME` and the caller's current working directory are
  under `/mnt` on WSL (the Windows filesystem, which is slow and the direct cause of git's own
  "I/O intensive operation" warning — spec 003's rationale for keeping repos under
  `~/workspaces`); low free disk space on the filesystem holding `$HOME`; a misconfigured locale;
  a plaintext `~/.netrc` with the wrong permissions; an overly permissive `umask`; and, when
  `docker` is installed, whether the caller can use it without `sudo` (root, or in the `docker`
  group).
- **FR-002**: `doctor` MUST print one PASS/WARN/FAIL line per check, MUST run every check
  regardless of earlier failures, and MUST exit non-zero if and only if at least one check FAILed.
- **FR-002a**: `doctor`'s output MUST be colorized and grouped under a labeled header per section
  for a real terminal, and MUST fall back to identical plain text (no ANSI escapes) when stdout
  isn't a terminal, `NO_COLOR` is set, or `TERM` is `dumb`, so piped or logged output (CI, a
  redirected file) never carries escape codes. Every PASS/WARN/FAIL line MUST keep the literal
  word (not just a color or icon), so the result stays meaningful without color and easy to
  `grep`.
- **FR-003**: `doctor` MUST NOT be wrapped with a fixed `PATH` at packaging time — it must observe
  the caller's actual environment.
- **FR-004**: Rolling back MUST be possible with home-manager's own generation-listing and
  re-activation mechanism, documented (README and/or a quickstart doc) rather than wrapped in new
  tooling, and verified against a real two-generation activate/rollback cycle during
  implementation.
- **FR-005**: The repository MUST include a CI workflow that runs `nix flake check` and runs
  `doctor` against a real activation of the default home-manager configuration, on every push and
  pull request.

### Key Entities

- **`doctor`**: the health-check command.
- **Home-manager generation**: home-manager's own pre-built mechanism this feature documents
  rather than reimplements.
- **CI workflow**: the repository's automated check-and-verify pipeline.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Running `doctor` on a correctly configured environment reports zero FAILs.
- **SC-002**: Running `doctor` after deliberately breaking one piece of the environment reports
  exactly that piece as FAIL and every other check still completes.
- **SC-003**: An engineer can roll back a broken update to a known-good generation in under one
  minute using only documented commands.

## Assumptions

- `doctor` reports on the pieces this repository itself provisions (specs 001-003, plus optional
  container tooling); it does not attempt to audit arbitrary third-party software.
