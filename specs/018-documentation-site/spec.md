# Feature Specification: Documentation Site

**Feature Branch**: `018-documentation-site`

**Created**: 2026-09-13

**Status**: Implemented

**Input**: User description: "A beautiful, easy-to-read HTML documentation site served by GitHub
Pages, starting with just-the-facts Getting Started for WSL then other platforms, then separate
newbie-usage and technical/Nix/AI-agent-workflow sections. Later revised: consolidate into one
self-contained `index.html` with client-side section routing and no external library (no HTMx, no
framework, no CDN) - plain modern HTML/CSS/JS only. Add a comprehensive 'Why?' section covering
every design decision's rationale, and slim the README down to a short pointer at this site."

## Background

The README originally carried the full explanation of this repository, "why" rationale included,
in one long scrolling page. That's a fine format for a `git clone`-and-read audience, but a poor
fit for a bookmarkable reference with real navigation, or for someone who wants installation steps
with no rationale in the way. This spec's first revision split that content across three static
HTML pages under `docs/`. A second revision consolidated those three pages into one
self-contained `docs/index.html` (all HTML/CSS/JS inlined, no separate asset files) using
client-side section routing implemented in plain CSS (`:target`/`:has()`), explicitly ruling out
any client-side routing library (HTMx included) per Constitution Principle V. That revision also
added a dedicated "Why?" section covering every real design decision's rationale, migrated out of
the README's own collapsible asides, and made this site (not the README) the comprehensive,
always-current documentation - the README now stays a short pointer to it, specifically to avoid
two documents that can silently drift out of agreement about the same feature.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Get running with no rationale in the way (Priority: P1)

Someone who just wants to get a working shell opens the site's Getting Started section and finds
their platform's exact steps, in order, with nothing to read except what to type.

**Why this priority**: This is the single most common reason anyone opens the site at all.

**Independent Test**: Open the site (no URL fragment), land on Getting Started by default, and
follow only the WSL subsection top to bottom, with no need to read any other section.

**Acceptance Scenarios**:

1. **Given** the site with no URL fragment, **When** it loads, **Then** the Getting Started
   section is the one visible by default.
2. **Given** the Getting Started section, **When** a Windows/WSL reader reads only that
   subsection, **Then** they have every command needed to reach a working shell, in run order.
3. **Given** the Getting Started section, **When** a Linux or macOS reader reads their platform's
   subsection instead, **Then** they find the equivalent steps with no WSL-specific content mixed
   in.

---

### User Story 2 - Look up how to do something day to day (Priority: P2)

An engineer already running this sandbox wants to remember how to add a credential, activate a
persona, or roll back a bad update, without re-reading everything.

**Independent Test**: From the site's top navigation, reach the "Using Your Sandbox" section in
one click from anywhere on the page; from that section's own sidebar, reach credentials,
`ws-repos`, `doctor`, sync, and personas each in one further click.

**Acceptance Scenarios**:

1. **Given** the site open on any section, **When** the reader clicks "Using Your Sandbox" in the
   top navigation, **Then** that section becomes visible with no full page reload, and the browser
   URL updates to a bookmarkable fragment.

---

### User Story 3 - Understand the machinery, or point an AI agent at it (Priority: P2)

An engineer who wants to actually understand Nix/flakes/home-manager, or who wants to hand this
repository to Claude Code/Codex/another agent and have it make a correct change, reads the
Technical Reference section first.

**Independent Test**: The Technical Reference section explains the flake/home-manager/persona
architecture and the spec-driven workflow, and gives concrete instructions for pointing an AI
coding agent at this repository.

**Acceptance Scenarios**:

1. **Given** the Technical Reference section, **When** an engineer wants to add a new tool or
   persona, **Then** the section explains where that change belongs (a persona module vs. the base
   profile) and which repository files govern the decision.
2. **Given** the Technical Reference section, **When** an engineer wants an AI agent to make a
   change to this repository, **Then** the section names the constitution, the writing-style
   guide, the SpecKit lifecycle, and this site's own comprehensive-docs role as things that agent
   must follow.

---

### User Story 4 - Understand why a choice was made, not just what it is (Priority: P2)

An engineer or reviewer wants to know why the repository does something a particular way (a plain
credentials file instead of encryption, personas instead of one big profile, a specific tool
included or deliberately left out) and finds a direct, dedicated answer instead of having to infer
intent from code or commit history.

**Why this priority**: A design decision without a recorded reason gets silently re-litigated or
accidentally reversed by someone (human or agent) who never knew it was deliberate.

**Independent Test**: From the "Why?" section's own sidebar, reach the rationale for any real
design decision described elsewhere on the site (credentials, secret scoping, personas, `ws-repos`
naming, v1-roadmap tools, prompt/Java tooling choices, the spec-driven workflow itself, and the
docs/README split) in one click.

**Acceptance Scenarios**:

1. **Given** a claim elsewhere on the site that a choice was deliberate (e.g. "personas keep the
   base profile small"), **When** the reader follows that claim's link, **Then** they land on the
   "Why?" section's matching subsection with the actual reasoning, not a restatement of the claim.

### Edge Cases

- What happens when a reader's browser has JavaScript disabled? Section routing itself MUST still
  work (it is implemented in CSS, not JavaScript); only the active-nav-link highlight, tab-title
  update, and code-block copy buttons are absent, with no error.
- What happens when a URL fragment points at a sub-heading inside a section, not the section's own
  top-level id (e.g. `#doctor`, which lives inside the "Using Your Sandbox" section)? The
  containing section MUST become visible (not just the sub-heading's immediate element), and the
  browser MUST still scroll to and reveal that sub-heading.
- What happens on a narrow (phone-width) screen? Top navigation and each section's own local table
  of contents must remain usable, not clipped, overflowing, or overlapping content.
- What happens if GitHub Pages is not yet enabled for this repository? The site's source must be
  fully correct and complete in the repository regardless; enabling Pages itself is a one-time
  repository-settings action outside this repository's own files (documented in this spec's
  Assumptions).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST include a `docs/` directory whose entire site is one
  self-contained `index.html` file (HTML, CSS, and JavaScript all inlined in that one file) -
  no separate stylesheet or script file, no external CDN, no build step, no static-site generator,
  and no client-side routing library or JavaScript framework of any kind (explicitly including,
  but not limited to, HTMx) - suitable for GitHub Pages' "deploy from a branch" mode pointed at
  `main` / `docs`.
- **FR-002**: The site MUST include a `.nojekyll` marker so GitHub Pages serves the file as-is,
  without Jekyll processing.
- **FR-003**: Navigation between the site's sections MUST be implemented in plain CSS (the
  `:target` and `:has()` selectors), not JavaScript - so it keeps working with JavaScript
  disabled - and MUST update the browser's URL fragment so a section (or a sub-heading within one)
  is directly linkable and works with the browser's back button.
- **FR-004**: The site MUST have a Getting Started section, visible by default when the page loads
  with no URL fragment, presenting installation instructions with minimal surrounding rationale
  ("just the facts"): Windows/WSL first, followed by Linux, then macOS, then a manual/step-by-step
  equivalent.
- **FR-005**: The site MUST have a "Using Your Sandbox" section for newbie, day-to-day usage:
  credentials, shell features, `ws-repos`, `doctor`/rollback, keeping in sync, and workspace
  profiles (personas), written for someone who has already finished Getting Started.
- **FR-006**: The site MUST have a Technical Reference section covering: what
  Nix/flakes/home-manager actually are, this repository's own module layout (`flake.nix`, `home/`,
  `pkgs/`, `specs/`, personas), the spec-driven (SpecKit) workflow and the constitution's role, and
  concrete guidance for pointing an AI coding agent at this repository (which files govern its
  behavior, and where a given kind of change belongs).
- **FR-007**: The site MUST have a "Why?" section giving the actual reasoning behind every real
  design decision described elsewhere on the site or in the README (at minimum: why this
  repository exists at all; why Nix/home-manager over alternative toolchains; why a plain
  credentials file; why secrets are scoped per invocation; why the AI harness CLIs aren't
  Nix-packaged; why the base profile stays small and personas exist; why `ws-repos` is named that;
  why the v1-roadmap tools - Deno, Lefthook, Tailscale/Nebula - are provisioned the way they are;
  why oh-my-posh doesn't self-update; why there's no Java version manager; why every feature gets a
  spec; and why the documentation lives on this site rather than in the README). Every other
  section that makes a "this was deliberate" claim MUST link to that claim's matching "Why?"
  subsection.
- **FR-008**: The site MUST share one consistent top navigation (reachable from every section, in
  the same position, without a full page reload between sections) and one consistent visual style,
  so moving between sections never feels like a different page.
- **FR-009**: The site's prose MUST follow `.specify/memory/writing-style.md`, per the
  constitution's Documentation Voice principle, since it is exactly the kind of `docs/` guide that
  principle names.
- **FR-010**: The site MUST render correctly with JavaScript disabled (FR-003's routing already
  guarantees this); any JavaScript enhancement (the active-nav-link highlight, the tab-title
  update, copy buttons on code blocks) MUST be strictly additive, never required to read or
  navigate the content.
- **FR-011**: The site MUST be usable at phone width (no horizontal scrolling of page content;
  navigation remains reachable, wrapping onto additional lines rather than overflowing).
- **FR-012**: The README MUST stay a short overview (purpose, core concepts, a link to this site)
  rather than a comprehensive walkthrough; this site, not the README, MUST be the comprehensive,
  always-current documentation. A change that affects installation, day-to-day usage, or the
  technical architecture MUST update this site in the same commit; the README MUST only change
  when the short overview itself stops being accurate.

### Key Entities

- **`docs/index.html`**: the entire site - one self-contained file GitHub Pages serves directly.
- **Getting Started / Using Your Sandbox / Technical Reference / Why?**: the four sections this
  spec requires, each targeting a different reader intent, implemented as CSS-routed regions of
  the same document rather than separate pages.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reader following only the Getting Started section's WSL subsection reaches a
  working shell with no need to consult any other section.
- **SC-002**: Every section is reachable from every other section in exactly one click, with no
  full page reload.
- **SC-003**: The site works with no network access beyond loading the one file (no external
  font/script/stylesheet dependency, no external library), and with JavaScript disabled -
  including section routing itself.
- **SC-004**: Every "this was deliberate" claim elsewhere on the site links to a real, substantive
  answer in the "Why?" section, not a restatement of the same sentence.

## Assumptions

- Enabling GitHub Pages itself (repository Settings → Pages → source: Deploy from a branch → `main`
  / `docs`) is a one-time, human, repository-settings action this spec's files cannot perform -
  outside what any file in this repository can configure.
- The site's content is derived from, and MUST stay consistent with, this repository's specs and
  actual behavior; it does not introduce any capability the flake itself doesn't already have.
- `:has()` is assumed to be supported by the reader's browser (universal in actively updated
  Chrome, Edge, Safari, and Firefox as of this writing). A browser old enough to lack it is out of
  scope, the same way this repository doesn't target unsupported OS versions elsewhere.
