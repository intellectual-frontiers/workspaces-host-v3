# Implementation Plan: Documentation Site

**Branch**: `018-documentation-site` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/018-documentation-site/spec.md`

## Summary

A `docs/` directory holds three hand-written HTML pages (`index.html` = Getting Started,
`usage.html` = Using Your Sandbox, `technical.html` = Technical Reference) sharing one stylesheet
(`assets/style.css`) and one small, optional enhancement script (`assets/copy.js`, copy-to-clipboard
buttons on code blocks). No build step, no static-site generator, no external CDN dependency -
consistent with this repository's own "minimal toolchain" stance, just applied to documentation
instead of the flake. GitHub Pages serves `docs/` directly once a repository owner points Pages'
source at `main` / `docs` (a one-time settings action - see spec's Assumptions).

## Technical Context

**Language/Version**: Plain HTML5 + CSS3, one small vanilla-JS enhancement script (no framework,
no transpilation).

**Primary Dependencies**: None. No CDN font, no analytics script, no JS framework - system font
stack, hand-written CSS.

**Storage**: N/A (static files).

**Testing**: Manual visual check per page (desktop and phone-width viewport), and a plain-text
read-through with JavaScript disabled to confirm FR-008.

**Target Platform**: Any static web host; GitHub Pages specifically (deploy-from-branch mode).

**Project Type**: Static documentation site, sibling to the flake it documents.

**Performance Goals**: N/A (a handful of small static files).

**Constraints**: No build tooling, no external runtime dependency (Constitution's "Toolchain"
constraint, applied here to documentation rather than the flake itself); prose follows
`.specify/memory/writing-style.md` (Constitution Principle VI).

**Scale/Scope**: Three pages plus shared assets.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Principle V (simplicity): no static-site generator, no JS framework, no build step - the
  simplest thing that satisfies the spec.
- Principle VI (Documentation Voice): every page's prose follows the writing-style guide; the
  audit pass described there is run before this feature is considered done.

No violations requiring Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/018-documentation-site/
├── plan.md      # this file
└── spec.md
```

### Source Code (repository root)

```text
docs/
├── .nojekyll            # tells GitHub Pages not to run Jekyll over this directory
├── index.html            # Getting Started (WSL, Linux, macOS, manual)
├── usage.html             # Using Your Sandbox (newbie day-to-day usage)
├── technical.html         # Technical Reference (Nix/flake internals, AI-agent workflow)
└── assets/
    ├── style.css          # shared styles for all three pages
    └── copy.js            # optional copy-to-clipboard enhancement for code blocks
README.md                  # gets a short link to the published site
```

**Structure Decision**: A single `docs/` tree, GitHub Pages' own conventional location for
"deploy from a branch" mode - no separate branch, no generated output to keep in sync with source.

## Complexity Tracking

None.
