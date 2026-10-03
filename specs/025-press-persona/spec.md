# Feature Specification: Press Persona

**Feature Branch**: `025-press-persona`

**Created**: 2026-10-03

**Status**: Implemented

**Input**: User description: "A `press` persona for book and paper typesetting: asciidoctor with
asciidoctor-epub3, a texlive.combine with XeLaTeX/latexmk/the collections equivalent to Debian's
texlive-xetex/texlive-latex-extra/texlive-fonts-recommended/texlive-science, poppler_utils, qpdf,
librsvg, fontconfig, a headless JRE, and epubcheck - published as a second OCI image (spec 027),
not just a persona."

## Background

Intellectual Frontiers repositories that produce typeset output (books, papers, manuscripts) today
install this toolchain by hand (apt's texlive packages, gem installs for asciidoctor extensions,
...) - exactly the per-repo setup step the "no setup step after clone" rule eliminates. This
repository already has internal experience building an AsciiDoc pipeline (its own `docs-src`
manuscript, `pkgs/docs-toolchain`'s `bundlerEnv`-pinned Ruby gems), but that build is deliberately
narrow and pinned to this repo's own manuscript's exact gem versions - reusing it here would couple
a general-purpose persona to this repo's own internal docs tooling, so `press` uses nixpkgs'
own `asciidoctor-with-extensions` (bundling asciidoctor-pdf/-epub3/-diagram/-bibtex/-mathematical)
instead, confirmed directly: `asciidoctor -r asciidoctor-epub3 --version` succeeds.

TeX Live itself is the one genuinely heavy dependency here - its full closure dwarfs most of what
else this flake installs - so `texlive.combine` pulls in only `scheme-basic` plus the specific
collections the request named (nixpkgs names its own collections after upstream TeX Live's
collection names, not Debian's package names, hence `collection-xetex`/`collection-latexextra`/
`collection-fontsrecommended`/`collection-mathscience` rather than literally matching
`texlive-xetex`/etc.) plus `latexmk` (its own top-level texlive attribute). Every tool this persona
adds was built and run directly against this flake's pinned nixpkgs to confirm it actually works,
not assumed from a package name alone - `xelatex --version`, `latexmk -v`, `pdftotext -v`
(poppler_utils), `qpdf --version`, `rsvg-convert --version`, `java -version` (jre_headless), and
`epubcheck --version` all succeeded.

This weight is also why `press` gets its own published OCI image (spec 027,
`workspaces-host-v3-press`) rather than folding into the one base image every devcontainer defaults
to - pulling texlive into a container that never typesets anything would cost every other user
nothing but download time and disk.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Typeset a manuscript, no setup step (Priority: P3)

An engineer or AI agent working in a repo that typesets AsciiDoc/LaTeX output activates the
`press` persona (or pulls the `workspaces-host-v3-press` image), then runs that repo's own build
with no further install step.

**Why this priority**: Narrower audience than spec 024's base-profile additions - a persona/
second-image tier, the same as `compliance`/`networking`/`media`, not something every engineer
needs.

**Independent Test**: With the `press` persona activated, every acceptance command in the Done
Means section below succeeds.

**Acceptance Scenarios**:

1. **Given** no persona activated, **When** `doctor --all` runs, **Then** `xelatex`/`epubcheck`
   (press's marker tools) report as optional, pointing at `ws-persona activate press`, not a FAIL.
2. **Given** the `press` persona activated and `workspaces-host-update` run, **When**
   `asciidoctor -r asciidoctor-epub3 --version`, `xelatex --version`, `latexmk -v`, `pdftotext -v`,
   `qpdf --version`, `rsvg-convert --version`, `java -version`, and `epubcheck --version` all run,
   **Then** every one succeeds.
3. **Given** the `workspaces-host-v3-press` image (spec 027), **When** the same commands run inside
   it with no persona-activation step, **Then** every one succeeds (the image bakes this persona
   in directly).

### Edge Cases

- `press` is additive like every other persona: activating it changes nothing about the base
  profile or any other persona, and the default published image (spec 020) stays exactly as it
  was before this spec - only the new, second `workspaces-host-v3-press` image carries this
  toolchain baked in.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A new `press` persona (`home/profiles/press.nix`) MUST provide
  `asciidoctor-with-extensions`, a `texlive.combine` with `scheme-basic`, `collection-xetex`,
  `collection-latexextra`, `collection-fontsrecommended`, `collection-mathscience`, and `latexmk`,
  plus `poppler_utils`, `qpdf`, `librsvg`, `fontconfig`, `jre_headless`, and `epubcheck`.
- **FR-002**: `press` MUST be registered in `flake.nix`'s `personaModules` and `pkgs/ws-persona`'s
  persona table.
- **FR-003**: `doctor --all` MUST report press's tools as optional (pointing at `ws-persona
  activate press`) when the persona isn't active, and PASS when it is.
- **FR-004**: The documentation book's personas chapter MUST document `press`, consistent with
  every other persona's entry there.
- **FR-005**: `press` MUST also be available as a second published OCI image (spec 027 covers the
  publishing mechanics; this spec only requires the persona module itself be usable as one of that
  image's ingredients).

### Key Entities

- **`home/profiles/press.nix`**: the new persona module.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `ws-persona activate press && workspaces-host-update` makes every command in User
  Story 1's Acceptance Scenario 2 succeed.
- **SC-002**: No persona activated keeps those same commands failing (`command not found`),
  proving the persona is genuinely opt-in on a real host/VM install.

## Assumptions

- `press`'s own `pkgs/docs-toolchain` sibling relationship is intentional, not an oversight: both
  solve "AsciiDoc to PDF/EPUB," but `docs-toolchain` stays scoped to this repository's own
  manuscript build (exact pinned gem versions via Gemfile.lock/gemset.nix), while `press` is the
  general-purpose, nixpkgs-native equivalent for any repository that activates it.
