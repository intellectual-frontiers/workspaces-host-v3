# Feature Specification: Documentation Site

**Feature Branch**: `018-documentation-site`

**Created**: 2026-09-13

**Status**: Implemented

**Input**: User description: "A beautiful, easy-to-read HTML documentation site served by GitHub
Pages, starting with just-the-facts Getting Started for WSL then other platforms, then separate
newbie-usage and technical/Nix/AI-agent-workflow sections"

## Background

The README carries the full explanation of this repository, "why" rationale included, in one long
scrolling page. That's the right home for a `git clone`-and-read audience, but it's a poor fit for
someone who wants a bookmarkable reference site with real navigation, or who wants the
installation steps with none of the rationale in the way. This spec adds a small, hand-written
static site under `docs/`, served by GitHub Pages directly from this repository (no separate build
step, no static-site-generator dependency), split by what the reader actually needs: get running,
use it day to day, or understand how it's built and how to have an AI agent maintain it.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Get running with no rationale in the way (Priority: P1)

Someone who just wants to get a working shell opens the site's Getting Started page and finds
their platform's exact steps, in order, with nothing to read except what to type.

**Why this priority**: This is the single most common reason anyone opens the site at all - the
README's Installation section already does this well, but buries it under the same page as
everything else; a dedicated page with the WSL path first is the direct fix.

**Independent Test**: Open the Getting Started page, follow only the WSL section top to bottom,
with no need to scroll to or read any other section.

**Acceptance Scenarios**:

1. **Given** the Getting Started page, **When** a Windows/WSL reader reads only the WSL section,
   **Then** they have every command needed to reach a working shell, in run order.
2. **Given** the Getting Started page, **When** a Linux or macOS reader skips to their platform's
   section, **Then** they find the equivalent steps with no WSL-specific content mixed in.

---

### User Story 2 - Look up how to do something day to day (Priority: P2)

An engineer already running this sandbox wants to remember how to add a credential, activate a
persona, or roll back a bad update, without re-reading the whole README.

**Independent Test**: From the site's navigation, reach the credentials, personas, and rollback
instructions each in one click from any page.

**Acceptance Scenarios**:

1. **Given** the site's navigation, **When** the reader clicks "Using Your Sandbox," **Then** they
   land on a page covering credentials, `ws-repos`, `doctor`, sync, and personas, organized for a
   newbie audience.

---

### User Story 3 - Understand the machinery, or point an AI agent at it (Priority: P2)

An engineer who wants to actually understand Nix/flakes/home-manager, or who wants to hand this
repository to Claude Code/Codex/another agent and have it make a correct change, reads the
Technical Reference page first.

**Independent Test**: The Technical Reference page explains the flake/home-manager/persona
architecture and the spec-driven workflow, and gives concrete instructions for pointing an AI
coding agent at this repository (the constitution, the writing-style guide, and the spec-first
workflow it must follow).

**Acceptance Scenarios**:

1. **Given** the Technical Reference page, **When** an engineer wants to add a new tool or
   persona, **Then** the page explains where that change belongs (a persona module vs. the base
   profile) and which repository files govern the decision.
2. **Given** the Technical Reference page, **When** an engineer wants an AI agent to make a change
   to this repository, **Then** the page names the constitution, the writing-style guide, and the
   SpecKit lifecycle as the things that agent must follow.

### Edge Cases

- What happens when a reader's browser has JavaScript disabled? Every page must still be fully
  readable and navigable; the only JavaScript this feature adds (copy-to-clipboard buttons on code
  blocks) must degrade to a plain, still-selectable code block with no error.
- What happens on a narrow (phone-width) screen? Navigation and any page-local table of contents
  must remain usable, not clipped or overlapping content.
- What happens if GitHub Pages is not yet enabled for this repository? The site's source must be
  fully correct and complete in the repository regardless; enabling Pages itself is a one-time
  repository-settings action outside this repository's own files (documented in this spec's
  Assumptions).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST include a `docs/` directory containing a complete, static,
  dependency-free HTML site (no external CDN, no build step, no static-site generator) suitable
  for GitHub Pages' "deploy from a branch" mode pointed at `main` / `docs`.
- **FR-002**: The site MUST include a `.nojekyll` marker so GitHub Pages serves the directory's
  files as-is, without Jekyll processing.
- **FR-003**: The site MUST have a Getting Started page presenting installation instructions with
  minimal surrounding rationale ("just the facts"), Windows/WSL first, followed by Linux, then
  macOS, then a manual/step-by-step equivalent - mirroring README's own platform order.
- **FR-004**: The site MUST have a page for newbie, day-to-day usage: credentials, shell features,
  `ws-repos`, `doctor`/rollback, keeping in sync, and workspace profiles (personas), written for
  someone who has already finished Getting Started.
- **FR-005**: The site MUST have a Technical Reference page covering: what Nix/flakes/home-manager
  actually are, this repository's own module layout (`flake.nix`, `home/`, `pkgs/`, `specs/`,
  personas), the spec-driven (SpecKit) workflow and the constitution's role, and concrete guidance
  for pointing an AI coding agent at this repository (which files govern its behavior, and where a
  given kind of change belongs).
- **FR-006**: Every page MUST share one consistent navigation (linking to every other page and the
  GitHub repository) and one consistent visual style (shared stylesheet), so moving between pages
  never feels like a different site.
- **FR-007**: The site's prose MUST follow `.specify/memory/writing-style.md`, per the
  constitution's Documentation Voice principle, since it is exactly the kind of `docs/` guide that
  principle names.
- **FR-008**: The site MUST render correctly with JavaScript disabled; any JavaScript enhancement
  (e.g. a copy button on code blocks) MUST be strictly additive, never required to read or navigate
  the content.
- **FR-009**: The site MUST be usable at phone width (no horizontal scrolling of page content,
  navigation remains reachable).

### Key Entities

- **`docs/` site**: the static HTML/CSS(/JS) tree GitHub Pages serves directly.
- **Getting Started / Using Your Sandbox / Technical Reference**: the three pages this spec
  requires, each targeting a different reader intent.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reader following only the Getting Started page's WSL section reaches a working
  shell with no need to consult any other page.
- **SC-002**: Every page is reachable from every other page in exactly one click.
- **SC-003**: The site works with no network access beyond loading its own files (no external
  font/script/stylesheet dependency), and with JavaScript disabled.

## Assumptions

- Enabling GitHub Pages itself (repository Settings → Pages → source: Deploy from a branch → `main`
  / `docs`) is a one-time, human, repository-settings action this spec's files cannot perform -
  outside what any file in this repository can configure.
- The site's content is derived from, and MUST stay consistent with, the README and this
  repository's specs; it does not introduce any capability the flake itself doesn't already have.
