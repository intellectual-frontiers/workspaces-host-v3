# Feature Specification: Agent Harness Scaffolding

**Feature Branch**: `010-agent-harness-scaffolding`

**Created**: 2026-09-13

**Status**: Implemented

**Input**: User description: "Scaffold an AGENTS.md, MCP config, and Claude settings/hooks into
any project directory via a specify-cli and backlog-md powered agent harness template"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bring an AI coding agent up to speed on a new project (Priority: P2)

An engineer starts a new project (or opens an existing one that's never had an AI harness pointed
at it) and wants an AI coding agent to immediately understand: this project is provisioned by a
Nix flake (so packages belong in Nix, not `apt`/`brew`), secrets are never ambient, and where to
find build/test/lint commands — without writing that briefing by hand every time.

**Independent Test**: Run the scaffolding command in an empty directory; confirm `AGENTS.md`,
`.mcp.json`, and `.claude/settings.json` (with its hooks) are created.

**Acceptance Scenarios**:

1. **Given** an empty project directory, **When** the engineer runs the scaffolding command,
   **Then** the fixed template file set is copied in.
2. **Given** a project directory that already has one of the template's files (e.g. a hand-written
   `AGENTS.md`), **When** the engineer runs the scaffolding command, **Then** that file is left
   untouched and reported as skipped, never overwritten.

---

### User Story 2 - Spec-driven and task-tracked from day one (Priority: P3)

A scaffolded project also gets access to GitHub Spec Kit (`specify-cli`) and a lightweight
task tracker (`backlog-md`), so an engineer or agent can start spec-driven work immediately.

**Independent Test**: In a scaffolded project, run `specify init` and confirm it succeeds using
the packaged CLI with no separate install step.

**Acceptance Scenarios**:

1. **Given** the base profile is activated, **When** the engineer runs `specify`/`backlog`,
   **Then** both are already on `PATH` with no additional install step.

### Edge Cases

- What happens when the scaffolding command is run against a directory that isn't a project root
  (e.g. `$HOME` itself)? It should still only ever add files, never remove or modify anything
  already present.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The flake MUST package `specify-cli` (GitHub Spec Kit) and `backlog-md`
  (Backlog.md) and include both in the base profile's installed packages.
- **FR-002**: The flake MUST provide a `scaffold-agent-harness` command that copies a fixed set
  of template files (`AGENTS.md`, `.mcp.json`, `.claude/settings.json`,
  `.claude/hooks/session-start.sh`, `.claude/skills/README.md`) into a target directory (default:
  cwd), never overwriting a file that already exists there, and reporting each file as copied or
  skipped.
- **FR-003**: The template's `.claude/settings.json` MUST wire a `SessionStart` hook that reports
  whether `nix` is on `PATH`, whether a `flake.nix` is present in the project, and whether that
  flake's lock file resolves.
- **FR-004**: The template's `.mcp.json` MUST use Claude Code's own documented project-level MCP
  server format (`{"mcpServers": {...}}`).
- **FR-005**: The template's `AGENTS.md` MUST describe: that the project is provisioned by this
  flake (so packages belong in Nix, not `apt`/`brew`), that secrets are never ambient, and where
  to find build/test/lint commands and this project's skills.
- **FR-006**: The template content MUST be sourced from tracked plain files under
  `templates/agent-harness/` (not duplicated inline in the script), so it can be read, reviewed,
  and updated directly.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Scaffolding a fresh project takes one command and produces a working `AGENTS.md` +
  MCP config + Claude settings, with zero manual file creation.
- **SC-002**: Running the scaffolding command a second time never overwrites a file the engineer
  has since edited.

## Assumptions

- The template targets Claude Code specifically; other agent harnesses are out of scope for this
  spec.
