# Feature Specification: Workspace Repository Management (`mgit`)

**Feature Branch**: `003-workspace-repo-mgmt`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "mgit tool to clone and update many git repositories into one
predictable ~/workspaces layout and run the same command across many of them"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One predictable place for all my repos (Priority: P1)

An engineer lists the repositories they work on in one config file and runs a single command;
every repo is cloned (or updated, if already present) into one predictable folder layout under
`~/workspaces`.

**Why this priority**: A predictable layout is what lets a human, a teammate, CI, and an AI agent
all refer to "the repo" the same way regardless of whose machine they're on.

**Independent Test**: Populate the config with two repo entries on a clean `~/workspaces`; run the
ensure command; confirm both are cloned to their expected paths.

**Acceptance Scenarios**:

1. **Given** a config listing repos not yet cloned, **When** the engineer runs the ensure command,
   **Then** every listed repo is cloned to its predictable path under `~/workspaces`.
2. **Given** a config listing repos already cloned, **When** the engineer re-runs the ensure
   command, **Then** each repo is updated (pulled) in place rather than re-cloned, unless the
   config explicitly marks that entry for a fresh clone.

---

### User Story 2 - Know the state of everything at a glance (Priority: P1)

An engineer wants to know, across every repo under `~/workspaces`, which are dirty, ahead, behind,
or have no upstream, without visiting each one individually.

**Why this priority**: Losing track of uncommitted work across many repos is the exact failure
mode this tool exists to prevent.

**Independent Test**: Create a dirty repo and a clean repo under `~/workspaces`; run the status
command; confirm the dirty one is reported as such and the clean one is not.

**Acceptance Scenarios**:

1. **Given** several repos under `~/workspaces` in different states, **When** the engineer runs
   the status command, **Then** each repo's state (dirty / ahead / behind / no-upstream / clean)
   is reported.

---

### User Story 3 - See what's actually being tracked (Priority: P2)

An engineer wants to inspect which git hosts and repo paths are referenced by the workspace
config, to audit or clean it up.

**Why this priority**: Lower-frequency than clone/update/status, but needed to keep the config
itself trustworthy over time.

**Independent Test**: Run the inspect command against a populated config and confirm it lists the
distinct hosts and full set of repo paths.

**Acceptance Scenarios**:

1. **Given** a populated config, **When** the engineer runs the inspect command, **Then** the
   distinct git hosts and repo paths referenced are listed.

### Edge Cases

- What happens when two repos in the config reference each other (e.g. via a shared workspace
  file)? The tool must not infinite-loop; each repo path is only ensured once per run.
- What happens when `~/workspaces` doesn't exist yet? It (and an empty config) must be created
  automatically on first shell activation, without ever overwriting an existing config.
- What happens when a repo entry's remote is unreachable? That entry must fail clearly and the
  command must still process the remaining entries rather than aborting the whole run.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A single `mgit` command MUST provide `ensure`, `status`, and `inspect`
  subcommands, installed on `PATH` by the base profile (spec 001).
- **FR-002**: `mgit ensure` MUST clone a repo listed in the workspace config (default
  `~/workspaces/mgit.json`) to its predictable path under `~/workspaces` if absent, or pull it if
  already present, unless that entry is explicitly marked for a fresh reclone.
- **FR-003**: `mgit ensure` MUST support repos that reference other repos (e.g. via a multi-root
  workspace file), recursively ensuring each referenced repo, deduplicated per run.
- **FR-004**: `mgit status` MUST report git status (dirty / ahead / behind / no-upstream / clean)
  for every repo found under `~/workspaces`.
- **FR-005**: `mgit inspect` MUST list the distinct git hosts and the full set of repo paths
  referenced by the workspace config and any multi-root workspace files it discovers.
- **FR-006**: The base profile MUST create `~/workspaces` and an empty workspace config on first
  activation, without ever overwriting an existing config.
- **FR-007**: The environment health check (spec 004) MUST report whether `mgit` is on `PATH` and
  whether `~/workspaces` and its config exist.

### Key Entities

- **Workspace config**: `~/workspaces/mgit.json`, the list of repos to manage.
- **Repo entry**: one config entry — at minimum a remote URL and a target path, optionally marked
  for fresh-reclone-only behavior.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An engineer with an empty `~/workspaces` and a populated config has every listed
  repo cloned to its predictable path after one command.
- **SC-002**: Re-running the ensure command against already-cloned repos never loses uncommitted
  local changes.
- **SC-003**: The status command surfaces every dirty repo under `~/workspaces` in one invocation,
  with no repo silently skipped.

## Assumptions

- Repos are cloned over the protocol (HTTPS or SSH) the engineer's existing git credentials
  already support; this spec does not add its own auth mechanism.
- The workspace config format is a single JSON file; per-repo config files are out of scope.
