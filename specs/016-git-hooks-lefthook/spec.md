# Feature Specification: Git Hooks with Lefthook

**Feature Branch**: `016-git-hooks-lefthook`

**Created**: 2026-09-13

**Status**: Implemented

**Input**: User description: "Lefthook git hooks manager with a documented example lefthook.yml,
fulfilling v1's unfinished roadmap item"

## Background

workspaces-host-v1's own README carried an unchecked roadmap item: "Integrate Lefthook Git hooks
manager... with default... installation and standard `lefthook.yml` locations in repos." v1 never
built this. It is a clean fit for this repository's model: install the tool declaratively (Nix,
replacing v1's proposed `brew install`), and provide a documented, copy-in example config rather
than forcing hooks on every repo.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Adopt git hooks in a project with one file (Priority: P3)

An engineer wants pre-commit/pre-push checks (lint, format, a quick test) enforced locally,
consistently, without every project author hand-rolling `.git/hooks` scripts.

**Independent Test**: Copy the example config into a repo as `lefthook.yml`, run `lefthook
install`, make a commit, and confirm the configured hook runs.

**Acceptance Scenarios**:

1. **Given** `lefthook` is on `PATH` and a project has a `lefthook.yml`, **When** the engineer
   runs `lefthook install`, **Then** git hooks are wired up for that repo.
2. **Given** no project has adopted `lefthook.yml` yet, **When** the base profile is activated,
   **Then** nothing changes for any existing repo — this feature is purely opt-in per project.

### Edge Cases

- What happens in a repo that already has hooks under `.git/hooks` (e.g. from `pre-commit`)?
  `lefthook install` documents its own coexistence/migration behavior; this spec does not
  attempt to manage that — it only makes the tool available and documents the example config.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The base profile MUST install `lefthook`.
- **FR-002**: The repository MUST provide a tracked, documented example
  (`templates/lefthook.yml.example`) covering common hooks (`pre-commit`, `pre-push`) with
  placeholder commands, ready to copy into a project as `lefthook.yml`.
- **FR-003**: README MUST document how to adopt it: copy the example, run `lefthook install`.
- **FR-004**: The environment health check (spec 004) MUST report `lefthook` on `PATH`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An engineer can go from zero to working git hooks in a project in two commands
  (copy the example, `lefthook install`).

## Assumptions

- This spec makes the tool available and documents adoption; it does not retroactively install
  hooks into this repository itself or any other existing project.
