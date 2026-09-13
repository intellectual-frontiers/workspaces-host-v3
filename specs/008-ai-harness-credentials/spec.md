# Feature Specification: AI Harness Credential Scoping

**Feature Branch**: `008-ai-harness-credentials`

**Created**: 2026-09-13

**Status**: Draft (Backlog — not yet implemented; see constitution's spec-tiering policy)

**Input**: User description: "Scoped provisioning of AI coding agent (Claude Code, Codex, etc.)
credentials so an agent's own API keys follow the same never-unscoped secrets model"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - An agent CLI gets its key, nothing else does (Priority: P1)

An engineer declares an API key for an AI coding agent CLI (e.g. Claude Code) in their credentials
file. Running that CLI works immediately; the key is never visible to any other process in the
same shell.

**Why this priority**: This directly extends Constitution Principle III to the class of tool this
repository exists to support running safely.

**Independent Test**: Declare a dummy key, run the wrapped CLI, confirm it receives the key;
inspect a plain interactive shell's environment and confirm the key is absent.

**Acceptance Scenarios**:

1. **Given** a declared agent credential, **When** the engineer invokes the agent CLI through its
   documented wrapper, **Then** the credential is set only for that invocation.
2. **Given** the same declared credential, **When** the engineer inspects their interactive
   shell's ambient environment, **Then** the credential is not present.

### Edge Cases

- What happens when no credential is declared for an installed agent CLI? Invocation must still
  work as a plain pass-through (the CLI's own `login` flow remains a valid alternative), and
  `doctor` must WARN, not FAIL.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The base profile MUST make the common AI coding agent CLIs (at minimum Claude Code,
  OpenAI Codex CLI, Gemini CLI, GitHub Copilot CLI) installable/available, documented with their
  exact install command and binary name.
- **FR-002**: For each agent CLI with a declared credential, the system MUST provide a wrapper
  that sets that credential only for its own invocation of the real binary — a bash function using
  invocation-scoped variable export, never a shell-wide export.
- **FR-003**: The environment health check (spec 004) MUST report, per agent CLI: whether it is
  installed, and (if installed) whether a credential is configured — as a WARN, not a FAIL, since
  the CLI's own login flow is an equally valid alternative.
- **FR-004**: Documentation MUST describe the per-invocation-scoped behavior precisely, so an
  engineer understands why the credential does not appear in a plain `env`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero agent-CLI credentials appear in a plain interactive shell's ambient
  environment.
- **SC-002**: Every supported agent CLI works immediately after its credential is declared, with
  no additional configuration step.

## Assumptions

- Agent CLIs themselves are installed via their own documented package manager (e.g. `npm`), not
  hand-packaged in the flake, since their release cadence is far faster than a Nix pin could
  track without going stale.
