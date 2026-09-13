# Implementation Plan: Documentation Site

**Branch**: `018-documentation-site` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/018-documentation-site/spec.md`

## Summary

`docs/index.html` is the entire site: one self-contained file with HTML, CSS, and JavaScript all
inlined, no separate asset files, no external CDN, no build step, no static-site generator, and no
client-side routing library (HTMx explicitly considered and rejected in favor of plain CSS). Seven
sections (Getting Started, Personas, Using Your Sandbox, Try with AI, Technical Reference, Why?,
Inspiration) live in the same document; `:target`/`:has()` CSS selectors show exactly one at a
time based on the URL fragment, including correctly resolving a deep link to a sub-heading back to
its containing section. A small amount of JavaScript adds purely cosmetic enhancements
(active-nav-link highlight, tab-title update, copy-to-clipboard buttons) and is never required for
navigation or reading. GitHub Pages serves `docs/` directly once a repository owner points Pages'
source at `main` / `docs` (a one-time settings action - see spec's Assumptions). The README stays
a short pointer at this site rather than a second copy of the same content. Every real design
decision's rationale lives in "Why?"; every reference to an earlier repository or tool this
project's own lineage includes lives only in "Inspiration," so no other section requires that
history to be useful. Personas get their own top-level section (not buried in "Using Your
Sandbox") since discovering and activating one is common enough, and Nix-unfamiliar enough, to
deserve first-class placement right after "Getting Started."

## Technical Context

**Language/Version**: Plain HTML5 + CSS3 (including `:has()`) + one small vanilla-JS enhancement
block (no framework, no transpilation, no library of any kind).

**Primary Dependencies**: None. No CDN font, no analytics script, no JS framework, no client-side
routing library - system font stack, hand-written CSS, native browser fragment navigation.

**Storage**: N/A (one static file).

**Testing**: Automated headless-browser checks (Playwright) covering: default landing section,
each top-level section's own URL fragment, a deep link to a sub-heading resolving to its
containing section, phone-width layout with no horizontal overflow, and the exact same routing
checks repeated with JavaScript disabled. Manual visual read-through per section.

**Target Platform**: Any static web host; GitHub Pages specifically (deploy-from-branch mode). Any
browser supporting CSS `:has()` (universal in actively updated Chrome, Edge, Safari, Firefox).

**Project Type**: Static, single-file documentation site, sibling to the flake it documents.

**Performance Goals**: N/A (one static file).

**Constraints**: No build tooling, no external runtime dependency, no client-side routing library
(Constitution Principle V, applied here to documentation rather than the flake itself); prose
follows `.specify/memory/writing-style.md` (Constitution Principle VI); the README, not this site,
is the one that must stay short (spec FR-012).

**Scale/Scope**: One HTML file, seven sections.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Principle V (simplicity): no static-site generator, no JS framework or routing library, no build
  step - CSS-only routing is the simplest mechanism that satisfies the spec's linkability and
  no-JS requirements simultaneously, simpler than the JavaScript-driven alternative (HTMx or a
  hand-rolled router) that was considered and rejected.
- Principle VI (Documentation Voice): every section's prose follows the writing-style guide; the
  guide's own audit pass (banned words, em dashes, hedging) is run before this feature is
  considered done.

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
├── .nojekyll        # tells GitHub Pages not to run Jekyll over this directory
└── index.html        # the entire site: HTML + inline <style> + inline <script>
README.md              # short overview + link to the published site
```

**Structure Decision**: A single file under `docs/`, GitHub Pages' own conventional location for
"deploy from a branch" mode - no separate branch, no generated output to keep in sync with source,
no per-section files to keep navigation-consistent by hand.

## Complexity Tracking

None.
