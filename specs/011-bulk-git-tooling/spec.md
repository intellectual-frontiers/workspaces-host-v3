# Feature Specification: Bulk Git Tooling

**Feature Branch**: `011-bulk-git-tooling`

**Created**: 2026-09-13

**Status**: Implemented

**Input**: User description: "git-extras and git-xargs for making the same change across many
repos under ~/workspaces at once"

## Background

A newbie-simplification audit (see spec 014's own follow-up) reclassified `git-extras`, `semtag`,
and `git-standup` as power-user tooling and moved them behind the `agent-ops` persona (spec 014)
instead of the base profile — most engineers never reach for them on day one. `git-xargs` stays in
the base profile: it's the tool this spec's own primary user story (bulk-changing many repos at
once) is built around, and it's a single, self-contained binary with no bundled-subcommand
collision to reason about.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Land the same fix across many repos in one shot (Priority: P3)

An engineer with several repos under `~/workspaces` (managed by `ws-repos`, spec 003) wants to apply
the same script or command to every one of them and open a PR with the results, without a
hand-written loop.

**Independent Test**: Run the bulk tool against two repos with a trivial script; confirm both get
a branch, commit, and PR.

**Acceptance Scenarios**:

1. **Given** a list of repos and a script, **When** the engineer runs the bulk-change command,
   **Then** the script runs against each repo and a PR is opened per repo with the result.

---

### User Story 2 - Everyday multi-repo git shortcuts (Priority: P3)

An engineer wants convenience git subcommands (`git summary`, `git changelog`, `git effort`,
`git delete-merged-branches`, ...) available without hunting for a separate install.

**Independent Test**: Run `git summary` in any repo and confirm it works with no separate install
step.

### Edge Cases

- What happens when the bulk-change tool's own `git-standup`-style subcommand name collides with
  another installed tool that ships a same-named binary? The collision must be resolved
  predictably (one wins, documented), never a build failure.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `agent-ops` persona (spec 014) MUST install `git-extras`, a grab-bag of everyday
  `git <cmd>` subcommands.
- **FR-002**: The flake MUST package `git-xargs` (fetched from its GitHub releases for the
  current system) and include it in the base profile's installed packages, to run a command or a
  small callback against many GitHub repos at once and open a PR with the results in each.
- **FR-003**: The flake MUST package `semtag` (compute and optionally apply the next semantic
  version git tag) and `git-standup` (list a user's commits since their last working day, across
  one or more repos) and include both in the `agent-ops` persona's installed packages.
- **FR-004**: The environment health check (spec 004) MUST report `git-xargs` on `PATH` as part of
  its base-profile checks, and `git-extras`/`semtag`/`git-standup` as an informational WARN (not
  FAIL) when the `agent-ops` persona isn't active.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An engineer can apply and PR the same change across 3+ repos with one command,
  without writing a custom loop script.

## Assumptions

- `git-xargs`'s own documented flag set (repo selection, dry-run, PR title/body) is used as-is;
  this spec only makes sure the binary is on `PATH`, not a wrapper around it.
