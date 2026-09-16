# Feature Specification: AsciiDoc Manuscript & Multi-Format Docs

**Feature Branch**: `019-asciidoc-manuscript-docs`

**Created**: 2026-09-16

**Status**: Draft

**Input**: User description: "Switch the docs site from a hand-rolled single-page-app fetching
Markdown to a single AsciiDoc manuscript built, via Nix-pinned Asciidoctor tooling, into four real
output formats: a PDF book in a custom 'IF Press' imprint theme, browsable multi-page HTML in the
site's existing visual style, a single-page HTML edition, and an EPUB. `docs/index.html` stays the
site's home page — same hero graphic — but its buttons become format choices (Read online /
Single page / Download PDF / Download EPUB) instead of tier links. The content itself gets
rewritten to read like a book, not a website. Accept a build step (a Nix-pinned Ruby/Asciidoctor
toolchain) in exchange; a GitHub Actions workflow builds on push and deploys to Pages, so nothing
generated is committed to git."

## Background

Spec 018 built the docs site around one guarantee: no build step, ever. Every page was one
Markdown file under `docs/content/`, fetched and rendered client-side by a vendored library, so
adding a page meant writing a `.md` file and nothing else. That guarantee bought real simplicity
for two years' worth of revisions, but it also bounded what the site could ever be: a single-page
app, styled one way, read in a browser, and nothing else — no PDF anyone could hand to a client or
print, no EPUB for an e-reader, no way to read the whole thing front to back as one document
without clicking through fifteen separate pages.

This spec drops that guarantee on purpose. A single AsciiDoc manuscript (`docs-src/manuscript.adoc`,
including one chapter file per page) becomes the one source of truth, and a Nix-pinned Asciidoctor
toolchain converts it into four real, different artifacts: a typeset PDF book under a new "IF
Press" imprint, an EPUB for e-readers, a multi-page HTML edition keeping the current site's visual
identity, and a single-page HTML edition for anyone who wants to read or search the whole thing at
once. `docs/index.html` keeps its job as the front door — same hero illustration, same mascot — but
its buttons now hand the reader a format instead of a tier.

AsciiDoc's native admonitions, cross-references, and table/figure support replace the GitHub-style
alert-blockquote convention and ad hoc conventions spec 018 built by hand on top of plain Markdown.
Diagrams move from spec 018's runtime-rendered Mermaid (a 5.5MB library shipped to the reader's
browser and rendered on the fly) to build-time rendering: the same Mermaid diagram source is now
rendered once, during the build, into a static image embedded in every output format — no diagram
JavaScript ever reaches a reader, and a diagram now renders identically in a PDF as it does on a
web page.

The real cost, accepted deliberately: this repository now has a build step, and a second toolchain
(Ruby/Asciidoctor, pinned the same way everything else here is pinned — Constitution Principle I)
alongside the Nix/home-manager one the rest of the project runs on. Nothing generated is committed
to git; a GitHub Actions workflow builds all four formats on every push to `main` and deploys the
result directly to GitHub Pages, which means this repository's Pages source moves from "deploy
from a branch" to "GitHub Actions" (a one-time repository-settings change, same category as the
original Pages enablement in spec 018's own Assumptions).

The content itself is being rewritten, not just reformatted. Spec 018's pages were written to be
skimmed and jumped to; a book is read start to finish, or dipped into with a table of contents and
an index, and its prose has to carry context across a page turn the way a hyperlink used to carry
it across a click. Rewriting every chapter in that voice is this spec's other major piece of work,
alongside the toolchain itself.

Docs search, and the `docs/proto/` prototype exploring a zero-build Web Components chrome, predate
this decision (docs/content/going-further/architecture.md's account of the site's own history
covers both). This spec supersedes both: `docs/proto/` is retired outright once this pipeline is
verified working, and search is carried forward as a requirement on the multi-page HTML output
specifically (FR-024) rather than dropped, reusing the same client-side approach already proven in
that prototype — a build-time-generated index over the generated static pages, not a
fetch-every-page-at-runtime scheme, since the pages are no longer fetched at runtime at all.

This spec supersedes spec 018 in full; spec 018's Status is updated to point here rather than
rewritten line by line, since almost every one of its functional requirements assumed the
now-retired fetch-and-render-Markdown architecture.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pick a format and start reading (Priority: P1)

Someone who's never seen this project opens `docs/index.html`, sees the same hero illustration the
site has always shown, and picks how they want to read it: in a browser as a normal multi-page
site, as one long page, as a PDF they can save or print, or as an EPUB for an e-reader.

**Why this priority**: This is the site's front door and the entire point of offering more than one
format — if a reader can't find and choose a format in one glance, the other three formats don't
matter.

**Independent Test**: Open `docs/index.html` with no prior context, and reach a working copy of the
book in every one of the four formats, each in one click from the home page.

**Acceptance Scenarios**:

1. **Given** `docs/index.html`, **When** it loads, **Then** the hero image renders exactly as it
   does today, followed by four clearly labeled buttons: Read online, Single page, Download PDF,
   Download EPUB.
2. **Given** the home page, **When** a reader clicks "Read online," **Then** the multi-page HTML
   edition's first chapter opens, styled consistently with the rest of the site.
3. **Given** the home page, **When** a reader clicks "Download PDF" or "Download EPUB," **Then**
   the browser downloads (or opens, depending on the browser) a real, non-empty file in that
   format.

---

### User Story 2 - Read the multi-page edition like the current site (Priority: P1)

An engineer who wants to browse a specific chapter — install steps, a persona, a specific
troubleshooting page — reads the multi-page HTML edition and gets the same navigation, sidebar,
and page-turning experience the site already has today, now generated from the manuscript instead
of hand-maintained per page.

**Why this priority**: Most return visits are still "I need one specific answer," not "read me the
whole book" — the multi-page edition has to stay at least as usable as spec 018's site for this to
be a real replacement, not a regression dressed up as an upgrade.

**Independent Test**: From the multi-page edition's first chapter, reach every other chapter via
its own navigation/sidebar in the same number of clicks spec 018's site required, and move
front-to-back via a Previous/Next pager without returning to the sidebar.

**Acceptance Scenarios**:

1. **Given** the multi-page edition, **When** a reader is on any chapter, **Then** a consistent
   nav/sidebar shows every chapter in the current Part plus a way to reach every other Part.
2. **Given** any chapter, **When** the reader reaches its end, **Then** a Previous/Next pager moves
   to the adjacent chapter in book order, crossing Part boundaries at the ends of a Part the same
   way spec 018's tiers did.
3. **Given** a chapter with a diagram in its manuscript source, **When** the page renders, **Then**
   the diagram appears as a static image with no diagram-rendering JavaScript loaded and no
   run-time rendering delay.

---

### User Story 3 - Search the book without leaving the browser (Priority: P2)

A reader who already knows roughly what they want types it into the multi-page edition's search
box and jumps straight to the chapter that has it, the same way spec 018's site let them.

**Why this priority**: Search was a real, tested capability of the site being replaced; losing it
silently would be a regression even though it wasn't the focus of this pivot.

**Independent Test**: From any chapter in the multi-page edition, search a term that appears only
inside one chapter's body text (including inside a code example) and reach that exact chapter.

**Acceptance Scenarios**:

1. **Given** the multi-page edition, **When** a reader searches a term unique to one chapter,
   **Then** that chapter is the top result, with a snippet showing the match.
2. **Given** a search result, **When** the reader selects it, **Then** the browser navigates to a
   real URL for that chapter (not a hash-routed virtual page).

---

### User Story 4 - Get a print-quality book (Priority: P1)

Someone wants a document they can save, print, email, or read offline exactly as a professionally
typeset book looks — cover, title page, table of contents, running headers, page numbers — not a
browser printout.

**Why this priority**: This is the capability spec 018's architecture could never provide, and the
entire reason for this pivot.

**Independent Test**: Download the PDF and confirm it has a cover page, a table of contents with
working internal links, running headers/footers, and every chapter's actual content, with every
diagram rendered as a static image at print quality.

**Acceptance Scenarios**:

1. **Given** the downloaded PDF, **When** opened in any standard PDF reader, **Then** it opens on a
   cover page bearing the project's mascot art and the "IF Press" imprint, followed by a table of
   contents whose entries jump to the right page.
2. **Given** any page inside the PDF's body, **When** viewed, **Then** a running header/footer
   names the current Part/chapter and shows a page number.
3. **Given** a chapter with a diagram, **When** viewed in the PDF, **Then** the diagram renders as a
   crisp static image, not a broken reference or raw diagram source text.

---

### User Story 5 - Read on an e-reader (Priority: P2)

Someone wants to load the book onto a Kindle, Kobo, or similar device and read it like any other
ebook, with a working table of contents and reflowable text.

**Why this priority**: A real, if smaller, audience wants offline, reflowable reading distinct from
either the PDF (fixed layout) or the web edition (needs a browser).

**Independent Test**: Download the EPUB, open it in a standard EPUB reader/validator, and confirm
every chapter is present, the table of contents navigates correctly, and diagrams render as images.

**Acceptance Scenarios**:

1. **Given** the downloaded EPUB, **When** opened in an EPUB reader, **Then** its table of contents
   lists every Part and chapter and navigates correctly.
2. **Given** the EPUB, **When** validated against the EPUB3 spec (e.g. `epubcheck`), **Then** it
   passes with no errors.

---

### User Story 6 - Change a chapter without learning a new toolchain from scratch (Priority: P2)

Someone (human or AI coding agent) fixing a typo or updating a command in one chapter edits one
`.adoc` file, and a normal PR/CI cycle rebuilds and redeploys every format from it.

**Why this priority**: The whole point of one source feeding four formats is that a contributor
edits exactly one thing; if that stops being true in practice, the pivot has failed on its own
terms.

**Independent Test**: Edit one fact in one chapter file, push a branch, open a PR, and confirm CI
rebuilds all four formats and the change is visible in each once merged and deployed.

**Acceptance Scenarios**:

1. **Given** a one-line edit to a chapter's `.adoc` file, **When** pushed, **Then** CI builds all
   four formats without touching any other chapter file.
2. **Given** that PR merged to `main`, **When** the deploy workflow finishes, **Then** the change is
   visible in the live multi-page HTML, the single-page HTML, the PDF, and the EPUB.

### Edge Cases

- What happens when the Asciidoctor build fails (a broken cross-reference, invalid AsciiDoc syntax,
  a missing diagram source)? CI MUST fail the workflow run and MUST NOT deploy a partial or stale
  site — the previously deployed version stays live until a build succeeds.
- What happens when a Mermaid diagram's source is invalid? The build MUST fail loudly at that
  diagram, naming the offending block, rather than silently omitting the diagram or embedding a
  broken image reference in any output format.
- What happens when a reader's browser has JavaScript disabled? The multi-page and single-page HTML
  editions MUST remain fully readable (this is real content in the page now, not fetched
  client-side) — only the search box (User Story 3) and the "press / to search" affordance are
  unavailable, a strictly smaller regression than spec 018's "no content at all without JS."
- What happens to an old spec-018-era bookmark (`docs/index.html#day-to-day/personas`)? Out of
  scope for automatic redirection — the hash fragment is simply ignored by the new home page, which
  has no router. (See Assumptions.)
- What happens when someone downloads the PDF or EPUB on a platform with no reader installed? Out
  of this spec's control; the file itself MUST still be a valid, standards-conformant PDF/EPUB
  regardless of what's installed to open it.
- What happens when a chapter has no diagram? No diagram-rendering step runs for that chapter, and
  no diagram-related asset is produced for it, consistent with spec 018's "don't load what a page
  doesn't need."
- What happens if the Nix-pinned Ruby toolchain can't resolve a gem at build time (rubygems.org
  unreachable in CI)? The lockfile (`Gemfile.lock`/`gemset.nix`, see FR-018) MUST already pin every
  gem's exact source, so a successful prior build's lock file guarantees the same build succeeds
  again without needing network access to resolve versions — only initial lockfile generation
  needs rubygems.org reachable, not every build.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST contain a single manuscript source, `docs-src/manuscript.adoc`
  (AsciiDoc `book` doctype), which `include::`s one chapter file per page under
  `docs-src/chapters/<part>/<chapter>.adoc`, mirroring spec 018's tier/page structure 1:1 as
  Parts/chapters: Getting Started, Day to Day, Going Further, and FAQ. No page's content MUST exist
  in more than one place; the manuscript is the sole source for all four output formats.
- **FR-002**: Every chapter file MUST be reviewable and readable as prose on its own in a PR diff or
  directly on GitHub (AsciiDoc renders natively in GitHub's file browser), even though `include::`
  directives will show unresolved when a chapter file is viewed standalone there — the same
  trade-off already accepted for spec-file cross-references elsewhere in this repository.
- **FR-003**: All prose MUST follow `.specify/memory/writing-style.md` per the constitution's
  Documentation Voice principle, adapted to a book's own register: sustained, front-to-back
  narrative that carries context across a chapter boundary the way spec 018's prose carried it
  across a hyperlink, rather than a page written to be skimmed or jumped into cold. A chapter MUST
  NOT assume the reader clicked in from a sidebar; it MUST read correctly for someone who just
  turned the page from the previous chapter.
- **FR-004**: A callout (tip, warning, note) MUST use AsciiDoc's native admonition syntax
  (`NOTE:`, `TIP:`, `WARNING:`, `IMPORTANT:`, `CAUTION:`), not a hand-rolled convention, so every
  output format (PDF, EPUB, HTML) renders it with that format's own proper admonition styling.
- **FR-005**: A diagram MUST be authored as Mermaid source inside an AsciiDoc diagram block (an
  `asciidoctor-diagram` `[mermaid]` block or equivalent), rendered once at build time into a static
  image embedded in every output format. No output format MUST ship or load a diagram-rendering
  JavaScript library to a reader.
- **FR-006**: A cross-reference between chapters MUST use AsciiDoc's native `xref:`/`<<id>>` syntax,
  which the Asciidoctor build validates at build time — a broken cross-reference MUST fail the
  build (see Edge Cases), not silently produce a dead link the way a hand-typed
  `#tier/page/heading` hash could under spec 018.
- **FR-007**: The repository MUST include a Nix-pinned toolchain providing `asciidoctor`,
  `asciidoctor-pdf`, and `asciidoctor-epub3` (plus whatever diagram-rendering dependency FR-005
  needs), wired into `flake.nix` following this repository's existing package-registration pattern
  (Constitution Principle I: pinned by lockfile, not resolved at install time). Any Ruby gem not
  already packaged in the pinned nixpkgs revision MUST be pinned via a committed `Gemfile.lock` and
  `gemset.nix` (or equivalent), not resolved fresh on every build.
- **FR-008**: The build MUST produce exactly four artifacts from the one manuscript: a multi-page
  HTML edition (one file per chapter, styled per FR-011), a single-page HTML edition (one file,
  the whole book), a PDF (FR-009), and an EPUB3 (FR-010).
- **FR-009**: The PDF MUST use a custom "IF Press" imprint theme (an `asciidoctor-pdf` theme file
  under `docs-src/theme/`) derived from the site's existing visual identity (the mascot
  illustration, its established color palette and typography) — a cover page bearing the mascot art
  and imprint name, a title page, a table of contents with working internal links, running
  headers/footers naming the current Part/chapter, and page numbers.
- **FR-010**: The EPUB MUST validate cleanly against the EPUB3 spec (e.g. via `epubcheck`), include
  a working table of contents, and use a stylesheet consistent with the site's visual identity
  without assuming a fixed page size the way the PDF does.
- **FR-011**: The multi-page and single-page HTML editions MUST reuse the current site's visual
  design (colors, typography, layout) via a custom Asciidoctor HTML stylesheet/template under
  `docs-src/theme/`, not Asciidoctor's default stylesheet or a separate tool's own theme (e.g.
  Antora) — a reader MUST NOT be able to tell, from looks alone, that the site changed its build
  pipeline.
- **FR-012**: The multi-page HTML edition MUST keep spec 018's chrome expectations: one consistent
  nav reachable from every chapter, a sidebar listing the current Part's chapters, a Previous/Next
  pager in book order across Part boundaries, and usability at phone width (no horizontal
  scrolling, no clipped/overlapping nav or sidebar).
- **FR-013**: The multi-page HTML edition MUST include a search box, reachable from every chapter
  and focusable by pressing "/", searching across every chapter's title and body text (including
  code-example text) with typo tolerance and prefix matching, built from a search index generated
  at build time from the rendered chapters (not fetched/built at runtime the way spec 018's did) —
  carrying forward spec 018's FR-025a/FR-025b capability rather than dropping it.
- **FR-014**: `docs/index.html` MUST remain the site's home page, keep its existing hero image
  treatment, and show exactly four buttons: "Read online" (links into the multi-page edition's
  first chapter), "Single page" (the single-page HTML edition), "Download PDF," and "Download
  EPUB" — replacing spec 018's four tier-link buttons.
- **FR-015**: `docs/index.html`, the mascot images (`docs/mascot.jpg`, `docs/mascot-workflows.jpg`),
  `docs/logo.png`, and `docs/social-preview.jpg` stay hand-authored and git-tracked exactly where
  they are today; only `docs/content/`, `docs/vendor/`, and `docs/proto/` are retired (FR-020).
- **FR-016**: An "Inspiration" chapter (or chapter section) MUST carry forward spec 018's FR-013
  content unchanged in substance: naming and linking every earlier repository/tool this project's
  lineage includes, visually/structurally set apart from the FAQ's design-rationale entries.
- **FR-017**: A GitHub Actions workflow MUST build all four formats (via the Nix toolchain, FR-007)
  on every push to `main` and on every pull request (build-only, no deploy, for PR validation), and
  MUST deploy the build output to GitHub Pages via GitHub's Actions-based Pages deployment
  (`actions/upload-pages-artifact` + `actions/deploy-pages` or equivalent) on push to `main` only.
  No generated file (HTML, PDF, EPUB, search index) MUST be committed to any branch.
- **FR-018**: The deploy artifact MUST combine `docs/`'s hand-authored static files (FR-015) with
  the freshly generated build output (FR-008) into one directory before upload, so the deployed
  site serves `index.html` (the format picker) at its root alongside the generated editions.
- **FR-019**: The `.github/workflows/ci.yml` job that currently runs `nix flake check` MAY stay
  separate from the new docs-build-and-deploy workflow (FR-017); a docs build failure MUST NOT
  block or fail the existing flake/OCI/doctor checks, and vice versa.
- **FR-020**: Once the new pipeline is verified (Success Criteria below), `docs/content/*.md`,
  `docs/vendor/{marked.js,mermaid.min.js,minisearch.js}` (and their `.LICENSE.txt` files), and the
  entire `docs/proto/` prototype tree MUST be removed from the repository — none of them has a role
  once the manuscript and its build pipeline are the source of truth.
- **FR-021**: The README's pointer to the docs site (spec 018 FR-011) MUST be updated to describe
  the four formats and link `docs/index.html` as the entry point, rather than describing a
  single-page browsing experience.

### Key Entities

- **`docs-src/manuscript.adoc`**: the book-doctype master document, `include::`ing every chapter.
- **`docs-src/chapters/<part>/<chapter>.adoc`**: one AsciiDoc file per page/chapter — the actual
  content, readable on its own.
- **`docs-src/theme/`**: the IF Press PDF theme, the EPUB stylesheet, and the HTML
  stylesheet/template reused for the multi-page and single-page editions.
- **`docs/index.html`**: the hand-authored home page / format picker; unchanged in role from spec
  018 except for what its buttons link to.
- **The Nix-pinned Asciidoctor toolchain**: `asciidoctor` + `asciidoctor-pdf` + `asciidoctor-epub3`
  + a diagram-rendering dependency, wired into `flake.nix`, pinned by lockfile per Constitution
  Principle I.
- **The docs build-and-deploy workflow**: builds all four formats and deploys the combined artifact
  to GitHub Pages on push to `main`; validates the build (no deploy) on pull requests.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All four formats (multi-page HTML, single-page HTML, PDF, EPUB) build successfully
  from the manuscript via a single, reproducible command sequence using only the Nix-pinned
  toolchain — verified by an actual clean build, not assumed from the tool versions alone.
- **SC-002**: Every chapter's content exists in exactly one place (its `.adoc` chapter file); no
  fact is hand-duplicated across formats or between the manuscript and `docs/index.html`.
- **SC-003**: The PDF opens with a cover page, a working table of contents, running headers/footers,
  and every diagram rendered as a static image — verified by opening the actual generated file, not
  assumed from the theme file's configuration.
- **SC-004**: The EPUB passes `epubcheck` (or equivalent EPUB3 validation) with zero errors.
- **SC-005**: The multi-page HTML edition matches spec 018's navigation guarantees: every chapter
  reachable from every other chapter's nav/sidebar, a working Previous/Next pager front to back,
  and no horizontal overflow at 390px width — verified directly in a browser.
- **SC-006**: Search in the multi-page HTML edition returns the correct chapter for a query unique
  to that chapter's body or a code example inside it, verified as an actual search-and-navigate,
  not assumed from the index-generation code alone.
- **SC-007**: A one-line edit to a single chapter file, built and deployed through the real CI
  workflow, appears correctly in all four live formats with no other chapter's content changed.
- **SC-008**: `nix flake check` and the existing OCI/doctor CI jobs continue to pass unaffected by
  the new docs workflow's existence.
- **SC-009**: No JavaScript file is served to a reader of the PDF or EPUB; no diagram-rendering
  JavaScript is served to a reader of any format (verified by inspecting actual network requests
  for the HTML editions and the file contents of the PDF/EPUB).

## Assumptions

- Moving this repository's GitHub Pages source from "Deploy from a branch" to "GitHub Actions" is a
  one-time, human, repository-settings action (Settings → Pages → Build and deployment → Source)
  this spec's files cannot perform themselves — same category as spec 018's original Pages-enabling
  assumption.
- A spec-018-era bookmark or external link using the old `#tier/page` hash scheme is not
  redirected; this spec treats that URL scheme as retired along with the architecture that
  generated it (see Edge Cases). Any external link to the docs site pointing at the bare
  `docs/index.html` root still lands correctly on the new home page.
- Generating the initial `Gemfile.lock`/`gemset.nix` (FR-007) requires one-time network access to
  rubygems.org; every build after that lockfile exists (including in CI) uses only the pinned
  versions it records.
- Slide-deck output (`asciidoctor-revealjs`) and any imprint beyond a single PDF theme are out of
  scope for this spec; the manuscript structure (FR-001) does not preclude adding either later as a
  backlog spec.
