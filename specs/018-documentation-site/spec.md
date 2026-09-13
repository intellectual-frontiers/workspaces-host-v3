# Feature Specification: Documentation Site

**Feature Branch**: `018-documentation-site`

**Created**: 2026-09-13

**Status**: Implemented

**Input**: User description: "A beautiful, easy-to-read HTML documentation site served by GitHub
Pages, starting with just-the-facts Getting Started for WSL then other platforms, then separate
newbie-usage and technical/Nix/AI-agent-workflow sections. Later revised: consolidate into one
self-contained `index.html` with client-side section routing and no external library (no HTMx, no
framework, no CDN) - plain modern HTML/CSS/JS only. Add a comprehensive 'Why?' section covering
every design decision's rationale, and slim the README down to a short pointer at this site.
Further revised: move every historical reference (prior repositories, prior tools) out of every
other section into one dedicated 'Inspiration' section, framing this repository as those
repositories' spiritual successor rather than a port; add a 'Try with AI' section giving
copy/paste, natural-language prompts a newbie can hand to an AI coding agent instead of typing
commands themselves; add a 'Personas' section. Most recently: fold 'Personas' into 'Getting
Started' (a reader who just got a working shell is the natural moment to offer a specialized
toolset too); merge 'Why?' and 'Inspiration' into one unified 'FAQ' section, with the Inspiration
entries visually set apart within its sidebar; rename 'Technical Reference' to 'Contributing'."

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

A third revision separated "why a choice was made" from "what came before it." The "Why?" section
had accumulated real project history (an earlier repository's roadmap, a separate tool this
repository's own naming avoids colliding with) alongside its design rationale. That history moved
to a new, dedicated "Inspiration" section, so every other section explains this repository entirely
on its own terms, with no reader ever needing to know what came before it to use what's here now.
The same revision added a "Try with AI" section: copy/paste, natural-language prompts for common
tasks, written for a reader who would rather hand a task to their AI coding agent than learn the
underlying command, and a "Personas" section of its own, reachable right after "Getting Started."

A fourth revision folded two of those sections back together, having found the previous split
created more navigation than the content needed. "Personas" moved into "Getting Started" itself -
a reader who just finished installing is already in the right place to hear about a specialized
toolset, and the persona-activation command (`nix build`/flake-attribute syntax) is exactly the
kind of Nix detail Getting Started otherwise shields a newbie from, so surfacing it as a dedicated
top-nav destination overstated how separate a topic it really was. "Why?" and "Inspiration" merged
into one "FAQ" section for the same reason: both are optional, curiosity-driven reading that no
task on the site depends on, so splitting them across two nav entries cost more clicks than it
bought clarity. Within "FAQ," the Inspiration entries stay visually set apart in their own sidebar
group, so a reader can still tell "why" from "history" at a glance. "Technical Reference" was
renamed "Contributing," since its actual content (repository layout, the spec-driven workflow, the
constitution, AI-agent guidance, building and testing) is written for someone about to change this
repository, not someone reading for general background.

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
Contributing section first.

**Independent Test**: The Contributing section explains the flake/home-manager/persona
architecture and the spec-driven workflow, and gives concrete instructions for pointing an AI
coding agent at this repository.

**Acceptance Scenarios**:

1. **Given** the Contributing section, **When** an engineer wants to add a new tool or persona,
   **Then** the section explains where that change belongs (a persona module vs. the base profile)
   and which repository files govern the decision.
2. **Given** the Contributing section, **When** an engineer wants an AI agent to make a change to
   this repository, **Then** the section names the constitution, the writing-style guide, the
   SpecKit lifecycle, and this site's own comprehensive-docs role as things that agent must follow.

---

### User Story 4 - Understand why a choice was made, not just what it is (Priority: P2)

An engineer or reviewer wants to know why the repository does something a particular way (a plain
credentials file instead of encryption, personas instead of one big profile, a specific tool
included or deliberately left out) and finds a direct, dedicated answer instead of having to infer
intent from code or commit history.

**Why this priority**: A design decision without a recorded reason gets silently re-litigated or
accidentally reversed by someone (human or agent) who never knew it was deliberate.

**Independent Test**: From the "FAQ" section's own sidebar, reach the rationale for any real
design decision described elsewhere on the site (credentials, secret scoping, personas, `ws-repos`
naming, v1-roadmap tools, prompt/Java tooling choices, the spec-driven workflow itself, and the
docs/README split) in one click.

**Acceptance Scenarios**:

1. **Given** a claim elsewhere on the site that a choice was deliberate (e.g. "personas keep the
   base profile small"), **When** the reader follows that claim's link, **Then** they land on the
   "FAQ" section's matching subsection with the actual reasoning, not a restatement of the claim.

---

### User Story 5 - Do a task by asking AI instead of typing the command (Priority: P2)

A newbie who doesn't yet know (or doesn't want to type) the exact command for a common task, like
adding a repository to their workspace, opens "Try with AI," copies a ready-made prompt, and pastes
it into their already-configured AI coding agent.

**Why this priority**: The whole point of this repository is a low barrier to entry; a reader who
can describe what they want in plain language shouldn't have to learn a CLI first.

**Independent Test**: From "Try with AI," copy the prompt for adding a repository to
`~/workspaces` and paste it, unmodified except for the repository's own URL, into a working AI
coding agent; the agent completes the task using commands this site itself documents.

**Acceptance Scenarios**:

1. **Given** the "Try with AI" section, **When** a reader wants to accomplish a task this site
   documents elsewhere (adding a repo, diagnosing a problem, rotating a credential, rolling back an
   update, activating a persona, scaffolding a project), **Then** they find a natural-language
   prompt for it, not a raw shell command to type themselves.

---

### User Story 6 - See what this repository grew out of, without needing to (Priority: P3)

A reader curious about this project's history, or trying to understand why `ws-repos` isn't called
`mgit`, opens "FAQ" and finds, in a visually distinct "Inspiration" group within its sidebar, the
earlier repositories and tools this one continues, framed as a lineage this repository builds on
rather than a compatibility promise it has to keep.

**Why this priority**: This context helps a curious reader, but no other section, and no actual
task on this site, requires it.

**Independent Test**: Read every section other than "FAQ" end to end with no prior knowledge of
any earlier repository or tool, and complete every task each section describes; separately, open
"FAQ" and find the same historical detail, set apart from the design-rationale entries, without
needing it for anything else on the site.

**Acceptance Scenarios**:

1. **Given** any section other than "FAQ," **When** it makes a claim or names a design decision,
   **Then** it does so without requiring the reader to know any earlier repository or tool this one
   grew out of.
2. **Given** the "FAQ" section, **When** a reader wants to know the earlier work this repository
   continues, **Then** its sidebar shows an "Inspiration" group, visually set apart from the
   design-rationale entries above it, naming and linking each one (a first version of this
   repository, a separate multi-repo tool, and a second version) as inspiration this repository
   builds on rather than a strict port of.

---

### User Story 7 - Find and activate a specialized toolset without reading Nix (Priority: P2)

A reader who just finished Getting Started wants a specialized toolset (Java, Python, Postgres,
Tailscale, and so on) and wants to know what's available and how to turn it on, without reading
`flake.nix` or learning the `nix build`/flake-attribute syntax first.

**Why this priority**: Personas exist specifically to serve engineers who aren't Nix-literate;
burying "how do I get one" several sections after Getting Started works against that goal.

**Independent Test**: From Getting Started's own sidebar, reach "Personas" in one click, right
after "Verify it worked"; from there, name every available persona and the exact command to
activate one without reading any other section.

**Acceptance Scenarios**:

1. **Given** Getting Started's own sidebar, **When** a reader looks for personas, **Then**
   "Personas" appears there, between "Verify it worked" and "What's next."
2. **Given** the "Personas" content, **When** a reader wants to know what's available or what's
   already active, **Then** they find `ws-persona list`/`ws-persona current` and the exact
   activation command, with no need to construct a flake attribute by hand.

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
- What happens when a section other than "FAQ" would otherwise need to justify a naming or scoping
  choice that traces back to an earlier repository or tool? That section states the current,
  present-tense fact (the name, the scope, the behavior) and links to "FAQ" for the reasoning,
  which in turn links to its own "Inspiration" entries for the earlier work behind it, rather than
  restating that history itself.
- What happens if a reader pastes a "Try with AI" prompt into an agent that isn't yet configured
  (no AI CLI installed, no credential set)? The prompt itself doesn't handle that case; "Try with
  AI" assumes "Setting up AI coding agents" (part of "Using Your Sandbox") is already done, and
  links there.

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
  equivalent, then how to verify the install worked, then Personas (FR-015), then what to do next.
- **FR-005**: The site MUST have a "Using Your Sandbox" section for newbie, day-to-day usage:
  credentials (including authenticating `gh`/`glab` for private repositories), shell features,
  `ws-repos`, `doctor`/rollback, and keeping in sync, written for someone who has already finished
  Getting Started. It MUST keep only a short pointer to Getting Started's "Personas" content
  (FR-015), not a second copy of it.
- **FR-006**: The site MUST have a "Contributing" section covering: what Nix/flakes/home-manager
  actually are, this repository's own module layout (`flake.nix`, `home/`, `pkgs/`, `specs/`,
  personas), the spec-driven (SpecKit) workflow and the constitution's role, and concrete guidance
  for pointing an AI coding agent at this repository (which files govern its behavior, and where a
  given kind of change belongs).
- **FR-007**: The site MUST have a "FAQ" section giving the actual reasoning behind every real
  design decision described elsewhere on the site or in the README (at minimum: why this
  repository exists at all; why Nix/home-manager over alternative toolchains; why a plain
  credentials file; why secrets are scoped per invocation; why the AI harness CLIs aren't
  Nix-packaged; why the base profile stays small and personas exist; why `ws-repos` is named that;
  why the v1-roadmap tools - Deno, Lefthook, Tailscale/Nebula - are provisioned the way they are;
  why oh-my-posh doesn't self-update; why there's no Java version manager; why every feature gets a
  spec; and why the documentation lives on this site rather than in the README), and, within the
  same section but visually set apart in its own sidebar group (FR-014), an "Inspiration" set of
  entries. Every other section that makes a "this was deliberate" claim MUST link to that claim's
  matching "FAQ" subsection.
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
- **FR-013**: The site MUST have a "Try with AI" section giving copy/paste, natural-language
  prompts (not raw shell commands) for common tasks a newbie would otherwise have to look up and
  type themselves (at minimum: adding a repository to `~/workspaces`, diagnosing a problem with
  `doctor`, adding or rotating a credential, rolling back a broken update, activating a persona,
  and scaffolding a new project). Each prompt MUST assume "Setting up AI coding agents" is already
  done and MUST link to it.
- **FR-014**: Within "FAQ" (FR-007), an "Inspiration" group of entries MUST name and link every
  earlier repository or tool this project's own lineage includes (a first version of this
  repository, the separate multi-repository tool `ws-repos` takes its pattern from, and a second
  version), framing this repository as their spiritual successor, not a strict port or a promise
  of behavioral compatibility with any of them, and MUST be visually set apart from "FAQ"'s
  design-rationale entries in the section's own sidebar (a distinct labeled group, not interleaved
  with them). Every other section on the site MUST describe this repository entirely on its own,
  present-tense terms, with no reader needing to know any of that history to install, use, or
  understand it; a section whose reasoning traces back to that history MUST link to "FAQ"'s
  Inspiration entries rather than restate the history itself.
- **FR-015**: Getting Started (FR-004) MUST include a "Personas" subsection, positioned after
  verifying the install worked and before "What's next," giving: every persona and what it adds
  (the same table spec 014 requires), how to discover and check personas (`ws-persona
  list`/`ws-persona current`), and the exact command to activate one. "Using Your Sandbox" MUST
  keep only a short pointer to it (not a second copy of the table or the activation command),
  consistent with FR-012's one-canonical-answer rule.

### Key Entities

- **`docs/index.html`**: the entire site - one self-contained file GitHub Pages serves directly.
- **Getting Started / Using Your Sandbox / Try with AI / Contributing / FAQ**: the five sections
  this spec requires, each targeting a different reader intent, implemented as CSS-routed regions
  of the same document rather than separate pages. "Personas" lives inside Getting Started;
  "Inspiration" lives inside FAQ, visually set apart from its design-rationale entries.

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
  answer in the "FAQ" section, not a restatement of the same sentence.
- **SC-005**: A reader with no prior knowledge of any earlier repository or tool this project grew
  out of can read every section, and every part of "FAQ" except its "Inspiration" group, and
  complete every task those sections describe with no gap in understanding; "Inspiration" is the
  only part of the site that names or links that earlier work.

## Assumptions

- Enabling GitHub Pages itself (repository Settings → Pages → source: Deploy from a branch → `main`
  / `docs`) is a one-time, human, repository-settings action this spec's files cannot perform -
  outside what any file in this repository can configure.
- The site's content is derived from, and MUST stay consistent with, this repository's specs and
  actual behavior; it does not introduce any capability the flake itself doesn't already have.
- `:has()` is assumed to be supported by the reader's browser (universal in actively updated
  Chrome, Edge, Safari, and Firefox as of this writing). A browser old enough to lack it is out of
  scope, the same way this repository doesn't target unsupported OS versions elsewhere.
