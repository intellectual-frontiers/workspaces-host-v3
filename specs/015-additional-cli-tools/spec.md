# Feature Specification: Additional CLI Tools

**Feature Branch**: `015-additional-cli-tools`

**Created**: 2026-09-13

**Status**: Implemented

**Input**: User description: "Ported utilities missing from the base profile: gopass, wget, a
directly exposed rclone, git-chglog, the Deno runtime, SSH agent auto-start, and a cdp alias"

## Background

A parity audit against workspaces-host-v1 (`strategy-coach/workspaces-host`) found several small,
genuinely useful utilities that neither v2 nor v3 ever ported, despite v1 treating them as
everyday tools: `gopass` (general secrets management), `wget`, `rclone` as a directly-runnable
command (v2/v3 only ever vendored it inside `sensitivectl`'s own wrapped `PATH`), `git-chglog`
(changelog generation, part of v1's documented release flow), the Deno runtime (v1 called it "a
core requirement," recommending `deno`+`dax` over `make` for custom task running — v2 only
avoided requiring Deno for *this repository's own* scripts, never addressed whether it should
still be available to engineers as a general tool), SSH agent auto-start on login, and a `cdp`
(cd-to-git-root) alias.

A later newbie-simplification audit (see spec 014's own follow-up) reclassified `gopass` and
`deno` as more specialized than `wget`/`rclone`/`git-chglog`/SSH-agent-autostart/`cdp`, and moved
the former two behind the `agent-ops` persona (spec 014) instead of the base profile. The other
three tools and the SSH/`cdp` conveniences stay in the base profile as originally specified below.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Everyday utilities just work (Priority: P3)

An engineer reaches for `wget`, `git-chglog`, or `rclone` and finds them already on `PATH` in the
base profile, the same as every other tool it installs; an engineer doing agent-ops/automation
work activates that persona and finds `gopass`/`deno` there too.

**Independent Test**: On an activated profile, run each tool's `--version`/`--help` and confirm
it resolves with no separate install step.

**Acceptance Scenarios**:

1. **Given** an activated base profile, **When** the engineer runs any of `wget`, `git-chglog`,
   `rclone`, **Then** each is on `PATH`.
2. **Given** an activated `agent-ops` persona, **When** the engineer runs `gopass` or `deno`,
   **Then** each is on `PATH`.

---

### User Story 2 - SSH agent is ready without a manual step (Priority: P3)

An engineer with an SSH key opens a new login shell and their SSH agent is already running with
their key loaded, without running `ssh-agent`/`ssh-add` by hand every session.

**Independent Test**: With an `id_ed25519` or `id_rsa` present, open a new login shell and
confirm `ssh-add -l` lists a key with no manual step.

**Acceptance Scenarios**:

1. **Given** a private key exists at `~/.ssh/id_ed25519` or `~/.ssh/id_rsa`, **When** a new login
   shell starts, **Then** an SSH agent is running and that key is loaded.
2. **Given** no private key exists, **When** a new login shell starts, **Then** nothing happens —
   no error, no agent started needlessly.

### Edge Cases

- What happens when a key is already loaded in an existing agent from a prior shell? Re-adding
  MUST be a no-op, never prompt for a passphrase repeatedly across every new shell.
- What happens when a key has a passphrase? The first `ssh-add` in a session may prompt once;
  this is standard `ssh-add` behavior, not something this feature changes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The base profile MUST install `wget`, `rclone`, and `git-chglog` directly in
  `home.packages` (not merely as a build-time dependency of another package). The `agent-ops`
  persona (spec 014) MUST install `gopass` and `deno` the same way.
- **FR-002**: The `agent-ops` persona MUST alias `deno-run` to `deno run -A` and `deno-test` to
  `deno test -A`.
- **FR-003**: The base profile MUST alias `cdp` to change to the current git repository's
  top-level directory.
- **FR-004**: Every login shell MUST start an SSH agent and load the first private key found
  among `~/.ssh/id_ed25519`, `~/.ssh/id_rsa` (in that order) if the agent has no keys loaded yet,
  and MUST do nothing if neither exists.
- **FR-005**: The environment health check (spec 004) MUST report `wget`, `git-chglog`, and
  `rclone` on `PATH` as part of its base-profile checks, and `gopass`/`deno` as an informational
  WARN (not FAIL) when the `agent-ops` persona isn't active.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All five tools are usable with no manual install step — three immediately after
  base-profile activation, `gopass`/`deno` immediately after activating the `agent-ops` persona.
- **SC-002**: An engineer with an existing SSH key never has to manually start `ssh-agent` for a
  normal session.

## Assumptions

- `gopass` is provisioned as a general-purpose, standalone tool here — it is not integrated with
  the credentials file (spec 002) or `workspacesHost.secrets` (spec 002's sops path); an engineer
  who wants it can adopt it independently, the same relationship it had in v1.
