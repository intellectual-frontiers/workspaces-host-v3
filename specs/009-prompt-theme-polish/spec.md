# Feature Specification: Prompt Theming & Font Polish

**Feature Branch**: `009-prompt-theme-polish`

**Created**: 2026-09-13

**Status**: Implemented

**Input**: User description: "Prompt theming and font setup polish (oh-my-posh theme, Nerd Font
installation and verification)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The prompt looks right, with icons (Priority: P3)

An engineer's prompt renders the polished, checked-in theme with legible icons (branch, folder,
clock, etc.), not fallback boxes — including the terminal-side font step spec 001's baseline
setup does not cover.

**Independent Test**: Activate the profile, install the documented font on the terminal side per
the per-environment instructions, open a new shell, and visually confirm icons render.

**Acceptance Scenarios**:

1. **Given** an activated profile and the documented terminal font step completed, **When** a new
   shell opens, **Then** the prompt renders its icons instead of fallback boxes.

### Edge Cases

- What happens when the engineer skips the terminal font step? The prompt must still be fully
  functional (branch name, path, etc. as plain text/boxes) — never a broken or blank prompt.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The base profile MUST install a Nerd Font patched monospace font family into the
  user profile and enable fontconfig discovery of it.
- **FR-002**: Documentation MUST give exact, per-environment (WSL2/Windows Terminal, Linux VM,
  bare-metal Linux, generic fallback) steps and the exact font family name required to make the
  terminal actually render with the installed font.
- **FR-003**: The checked-in oh-my-posh theme MUST render correctly (semantically identical
  generated config) across every profile this repository builds.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An engineer following the documented per-environment font steps sees prompt icons
  render correctly on first try.

## Assumptions

- This spec only covers the visual/font polish layer; the underlying prompt integration itself is
  spec 001's concern.
