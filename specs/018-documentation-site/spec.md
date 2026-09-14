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
commands themselves; add a 'Personas' section. Then: fold 'Personas' into 'Getting Started' (a
reader who just got a working shell is the natural moment to offer a specialized toolset too);
merge 'Why?' and 'Inspiration' into one unified 'FAQ' section, with the Inspiration entries
visually set apart within its sidebar; rename 'Technical Reference' to 'Contributing'. Then: add
an 'Autocomplete UX' subsection to Getting Started explaining why bash's typing can feel slow and
both fixes (a `bleopt` setting, or the new `fish` persona); document the `fish` persona in
Personas and in a new FAQ entry. Then: add a mascot illustration as the project's visual identity,
split across a hero panel and a 'Workhorse in Action' panel. Then, substantially revised:
restructure the entire site into a graduated approach - Getting Started, Day to Day, and Going
Further tiers, each use-case driven rather than organized by topic - and move every page's content
out of the single HTML file into plain Markdown files, fetched and rendered client-side by one
vendored library (the site's only dependency), so new pages and tiers can be added by writing a
`.md` file rather than editing one enormous HTML document. Most recently: move both mascot
images off the Getting Started and Day to Day page heroes onto a new home splash page (the
default, empty-hash landing spot) that shows just the hero image and one large button per tier;
content pages now carry no large graphics. Add MermaidJS, a second vendored, lazily loaded
library, so a content page that genuinely benefits from a diagram (a flow, a decision, an
architecture relationship) can include one."

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

A fifth revision added an "Autocomplete UX" subsection to Getting Started, between verifying the
install and Personas, after an engineer reported bash's typing feeling slow. The root cause
(`blesh`'s default keystroke-time auto-completion) has two real fixes - a `bleopt` setting for
anyone who wants to keep bash, or spec 014's new `fish` persona for anyone who wants a native line
editor instead - and this subsection is where a reader hits that choice, right next to where
Personas already explains how to activate one. The Personas table and the FAQ both gained a
`fish` entry to match.

A sixth revision added a mascot illustration (a Clydesdale draft horse pulling a cart of "CODE",
"CONFIG", and "TOOLS" crates) as the project's visual identity. The source artwork is one tall
poster with two distinct halves - a hero panel (the horse and cart, ending at the ground) above a
"Workhorse in Action" grid of eight small vignettes (Develop, Explore, Guide, Automate, Recharge,
Adapt, Stay Secure, Go Further) - and showing the whole poster in one place made the hero image
too tall and the vignette grid too small to read. The two halves were cropped into two separate
images instead: the hero panel (`docs/mascot.jpg`) and the vignette grid (`docs/mascot-workflows.jpg`).
A landscape crop of the hero panel exists as `docs/social-preview.jpg`, sized to GitHub's own
recommendation for a repository's social-preview image, for a human to upload via repository
Settings (see Assumptions).

### Seventh revision: a graduated structure, and content moved out of the HTML

The site had grown to five flat sections, and every one of them except "Contributing" was aimed
at a newcomer - there was no path for an engineer who already had a working sandbox and wanted a
real, task-shaped answer to something beyond the basics (combining personas for a specific role,
personalizing with `local.nix`, team secrets, writing a new persona, container/CI parity). And
"Contributing" itself conflated two different readers: someone wanting to *use* this sandbox more
deeply, and someone about to *change the repository itself*. Organizing by topic (credentials,
shell, repos, doctor...) rather than by task also meant a reader had to already know which topic
their goal fell under before they could find it.

This revision restructures the site into three graduated tiers, each genuinely use-case driven -
a heading names a task ("Combine personas for your role," "Add a tool or write a new persona"),
not a topic:

- **Getting Started**: install, verify, and a true first day - unchanged in spirit from every
  earlier revision, trimmed to stop once the reader has a working shell, one repo cloned, and a
  green `doctor`.
- **Day to Day** (renamed from "Using Your Sandbox"): the ongoing tasks an engineer actually
  returns to - personas, credentials, working across git hosts, staying in sync and recovering
  from a bad update, AI coding agents, everyday tools. "Try with AI"'s prompts moved into their
  matching task on each page instead of staying a separate section, so a reader finds the prompt
  right next to the command it replaces rather than in a second place entirely.
- **Going Further** (renamed from "Contributing," and no longer only for someone about to modify
  the flake): a light, deliberately short number of real advanced use cases - personalizing with
  `local.nix`, adding a tool or writing a new persona, team secrets with `sops`, container/CI
  parity, and extending the repository with an AI agent (which absorbs the old "Contributing"
  content, since a reader who wants to add a persona or a tool is, in effect, extending the repo
  either way). The pure architecture-tour material (what Nix/a flake/home-manager actually are,
  the repository's file layout) that doesn't fit a task shape stays here too, as its own page,
  rather than forcing it into an artificial task or adding a fourth nav destination just for
  reference material.
- **FAQ**: unchanged in role - the "why" layer every tier still links into, Inspiration included.

Splitting five sections' worth of hand-authored HTML into roughly fifteen graduated pages made
maintaining one enormous `index.html` file, and a sidebar that had to be hand-kept in sync with
whatever headings happened to be in it, the wrong tradeoff. Page content moved to plain Markdown
files under `docs/content/<tier>/<page>.md`, fetched and rendered at navigation time by
[marked](https://github.com/markedjs/marked) - vendored into `docs/vendor/marked.js` (not loaded
from a live CDN), so the site still has no third-party dependency at request time, matching the
spirit of the "no external CDN" rule the single-file era enforced literally. `docs/index.html`
is now a thin shell (nav, CSS, a small router) rather than the content itself; a page's own
sidebar "On this page" list is generated from its actual rendered headings, so it can never drift
out of sync with a heading the way a hand-copied list could.

The real, accepted cost: JavaScript is now required to read any content. The previous
architecture's CSS-only routing specifically guaranteed the opposite (FR-003/FR-010/SC-003 in
every prior revision of this spec), and this revision deliberately drops that guarantee rather
than working around it - fetching and rendering a file's content is not something plain CSS can
do. A `<noscript>` fallback points a JavaScript-disabled reader at the content files directly on
GitHub instead of failing silently.

### Eighth revision: brand polish and a merged sidebar

Two rough edges from the graduated-tier restructuring got cleaned up once real screenshots made
them obvious. The top navigation stretched edge to edge regardless of viewport width, while every
page's own content stayed constrained to a centered 1040px column beneath it - the two no longer
visually agreed at anything wider than that column. The nav's actual content (brand mark, tier
links, GitHub link) now sits inside its own inner wrapper sharing `.page`/`.page-hero`'s exact
max-width and centering, so the nav and the content beneath it always share the same left and
right edges. The brand mark itself changed from the plain repository slug
(`workspaces-host-v3`, in `<code>`) to the project's own logo - the icon-only crop of the mascot's
head, `docs/logo.png`, sized for inline nav use, since the full badge-with-text logo bakes
"WORKSPACES HOST" into the image at a scale illegible in a 28px mark - paired with the plain text
"Workspaces Host." The version qualifier was never part of the project's actual name; it stays in
the repository slug (the GitHub link, the page `<title>`) and out of the one piece of text meant to
read as a brand.

Separately, the two-group sidebar ("Pages" above a page list, "On this page" above that page's own
headings) turned out to state the obvious with a label neither list actually needed - a reader can
tell a sibling page from a heading within the page they're on by position and indentation alone,
the same way a file tree doesn't caption itself "Folders" and "Files." Both labels were dropped;
the current page's own headings now nest directly beneath it as indented sub-items in one flat,
unlabeled list.

### Ninth revision: a home splash page, and MermaidJS diagrams

The mascot's two images had been carrying two different jobs at once: identity (this is
Workspaces Host) at the top of Getting Started, and a second, unrelated identity image atop Day
to Day, while every other tier's pages stayed plain. Neither placement was really about that
page's own content - a large hero illustration doesn't help someone mid-install any more than it
helps someone reading about credentials. Both images moved to a new home splash page instead: the
site's default landing spot (empty hash, or the explicit `#home`), showing only the hero
illustration, a one-line lede, and one large button per tier linking straight into that tier's
first page. The "Workhorse in Action" image, no longer needed as a second hero, now sits below the
button grid on the same splash page. Every content page across every tier lost its large graphic;
the splash page is the only place a reader sees one. An unrecognized hash now falls back to this
splash page rather than Getting Started's Install page, since a typo or a stale bookmark shouldn't
guess which tier the reader meant - the front door is a safer default than a guess.

The same revision added [MermaidJS](https://mermaid.js.org/) as a second vendored library, so a
content page that genuinely benefits from a diagram - a decision flow, a build/activation
pipeline, a sequence of steps across machines - can include one, written as a fenced ```` ```mermaid
```` code block directly in that page's Markdown, the same way GitHub itself renders Mermaid
blocks. This keeps every page that has one readable and reviewable as plain text in a PR diff or
directly on GitHub, matching FR-019's existing rule for page content generally, rather than adding
a second authoring format for diagrams alone. The vendored file itself (`docs/vendor/mermaid.min.js`)
is roughly 5.5MB, far too large to load on every page when most pages have no diagram at all, so
it loads lazily: only the first time a page's rendered content actually contains a Mermaid code
block, cached for the rest of the session once loaded. FR-018's earlier claim of "exactly one
vendored JavaScript library" no longer holds; see FR-018's revised text below. Diagrams stay a
deliberately light touch, added only where a diagram genuinely clarifies something a reader would
otherwise have to hold in their head - not retrofitted onto every page as decoration.

### Tenth revision: splash page polish, and a `ws-repos` layout diagram

The splash page's headline and lede duplicated what the hero illustration already says in its own
caption - "Workspaces Host," "Same reproducible workspace everywhere" - so both were dropped, and
the hero image itself now fills the full content width instead of the 520px cap every other
`.mascot` image on the site uses, with the button grid sitting directly beneath it. This is the
only place on the site the hero image runs full width; FR-024 is revised below to match.

The same revision added a Mermaid diagram to Day to Day's "Work across multiple git hosts" page,
showing the actual directory shape `ws-repos` produces
(`~/workspaces/<git-host>/<org>/<repo>`) for a multi-host example already on that page - a concrete
picture of the layout the surrounding prose describes in words.

Adding that diagram also surfaced a real bug in the lazy-load path: `mermaid.min.js` (roughly
5.5MB) can still be loading when a reader navigates to a different page, and the diagram `<div>`
its failure handler was about to write an error message into had already been removed from the
document by that navigation. Setting `.outerHTML` on a detached node throws. The fix checks
`.isConnected` before touching the node - a diagram that's no longer on the page has nothing left
to show an error into, so the failure handler now does nothing in that case rather than throwing
into the console.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Get running with no rationale in the way (Priority: P1)

Someone who just wants to get a working shell opens Getting Started and finds their platform's
exact steps, in order, with nothing to read except what to type.

**Why this priority**: This is the single most common reason anyone opens the site at all.

**Independent Test**: Open the site (no URL fragment), land on Getting Started's Install page by
default, and follow only the WSL subsection top to bottom, with no need to read any other page.

**Acceptance Scenarios**:

1. **Given** the site with no URL fragment, **When** it loads, **Then** Getting Started's Install
   page is the one shown by default.
2. **Given** the Install page, **When** a Windows/WSL reader reads only that subsection, **Then**
   they have every command needed to reach a working shell, in run order.
3. **Given** the Install page, **When** a Linux or macOS reader reads their platform's subsection
   instead, **Then** they find the equivalent steps with no WSL-specific content mixed in.

---

### User Story 2 - Do a real, ongoing task without re-reading everything (Priority: P1)

An engineer already running this sandbox wants a direct, task-shaped answer for something they
do repeatedly: combine two personas, authenticate against a new git host, recover from a bad
update, use an AI agent safely - not a topic-organized reference they have to search.

**Why this priority**: This is the tier most engineers spend the most time in, and the one the
old topic-organized "Using Your Sandbox" section served worst.

**Independent Test**: From the top navigation, reach "Day to Day" in one click from any tier; from
its own sidebar, reach every one of its pages (personas, credentials, repos, sync-recover,
ai-agents, everyday-tools) each in one further click, and find that page's own AI-agent prompt (if
it has one) alongside the manual steps, not in a separate section.

**Acceptance Scenarios**:

1. **Given** the site open on any tier, **When** the reader clicks "Day to Day" in the top
   navigation, **Then** that tier's default page loads with no full page reload, and the browser
   URL updates to a bookmarkable fragment.
2. **Given** a Day to Day page that has a matching AI-agent prompt, **When** the reader reaches
   the bottom of that page, **Then** the prompt is right there, not on a separate "Try with AI"
   page.

---

### User Story 3 - A light number of real advanced use cases (Priority: P2)

An engineer comfortable with the basics wants to personalize their setup, add a tool or write a
new persona, use team secrets, or point an AI agent at the repository to extend it - genuine
advanced tasks, not a repository-internals tour for someone who happens to be curious.

**Why this priority**: These are real, if less frequent, needs; keeping this tier deliberately
short (a handful of pages, not an exhaustive reference) matches how rarely most engineers actually
need it.

**Independent Test**: From "Going Further," reach every one of its pages (local-nix,
add-a-tool-or-persona, team-secrets, container-ci, extend-with-ai, architecture) in one click each;
follow "Add a tool or write a new persona" end to end and have everything needed to register a new
persona, with no separate lookup required.

**Acceptance Scenarios**:

1. **Given** "Going Further," **When** an engineer wants to add a new tool or persona, **Then**
   that page explains where the change belongs (base profile vs. a persona) and gives the concrete
   steps, including registering it with `ws-persona`.
2. **Given** "Going Further," **When** an engineer wants an AI agent to make a change to this
   repository, **Then** its "Extend the repo with an AI agent" page names the constitution, the
   writing-style guide, the SpecKit lifecycle, and this site's own comprehensive-docs role as
   things that agent must follow.

---

### User Story 4 - Understand why a choice was made, not just what it is (Priority: P2)

An engineer or reviewer wants to know why the repository does something a particular way (a plain
credentials file instead of encryption, personas instead of one big profile, a specific tool
included or deliberately left out) and finds a direct, dedicated answer instead of having to infer
intent from code or commit history.

**Why this priority**: A design decision without a recorded reason gets silently re-litigated or
accidentally reversed by someone (human or agent) who never knew it was deliberate.

**Independent Test**: From "FAQ"'s own sidebar, reach the rationale for any real design decision
described elsewhere on the site (credentials, secret scoping, personas, `ws-repos` naming,
v1-roadmap tools, prompt/Java tooling choices, the spec-driven workflow itself, this site's own
Markdown-fetching architecture, and the docs/README split) in one click.

**Acceptance Scenarios**:

1. **Given** a claim elsewhere on the site that a choice was deliberate (e.g. "personas keep the
   base profile small"), **When** the reader follows that claim's link, **Then** they land on
   "FAQ"'s matching entry with the actual reasoning, not a restatement of the claim.

---

### User Story 5 - See what this repository grew out of, without needing to (Priority: P3)

A reader curious about this project's history, or trying to understand why `ws-repos` isn't called
`mgit`, opens "FAQ" and finds, in a visually distinct "Inspiration" group within its sidebar, the
earlier repositories and tools this one continues, framed as a lineage this repository builds on
rather than a compatibility promise it has to keep.

**Why this priority**: This context helps a curious reader, but no other page, and no actual task
on this site, requires it.

**Independent Test**: Read every tier other than "FAQ" end to end with no prior knowledge of any
earlier repository or tool, and complete every task each page describes; separately, open "FAQ"
and find the same historical detail, set apart from the design-rationale entries, without needing
it for anything else on the site.

**Acceptance Scenarios**:

1. **Given** any tier other than "FAQ," **When** it makes a claim or names a design decision,
   **Then** it does so without requiring the reader to know any earlier repository or tool this one
   grew out of.
2. **Given** "FAQ," **When** a reader wants to know the earlier work this repository continues,
   **Then** its sidebar shows an "Inspiration" group, visually set apart from the design-rationale
   entries above it, naming and linking each one (a first version of this repository, a separate
   multi-repo tool, and a second version) as inspiration this repository builds on rather than a
   strict port of.

---

### User Story 6 - Find and activate a specialized toolset without reading Nix (Priority: P1)

A reader who just finished Getting Started wants a specialized toolset (Java, Python, Postgres,
Tailscale, and so on) and wants to know what's available and how to turn it on, without reading
`flake.nix` or learning the `nix build`/flake-attribute syntax first.

**Why this priority**: Personas exist specifically to serve engineers who aren't Nix-literate;
burying "how do I get one" several pages deep works against that goal.

**Independent Test**: From "Day to Day"'s own sidebar, reach "Combine personas for your role" in
one click; from there, name every available persona, how to check what's active, and the exact
command to activate one, without reading any other page.

**Acceptance Scenarios**:

1. **Given** "Day to Day"'s own sidebar, **When** a reader looks for personas, **Then** "Combine
   personas for your role" is the tier's first page.
2. **Given** that page's content, **When** a reader wants to know what's available or what's
   already active, **Then** they find `ws-persona list`/`ws-persona current` and the exact
   activation command, with no need to construct a flake attribute by hand.

---

### User Story 7 - Land somewhere, then pick a starting point (Priority: P1)

Someone who opens the site with no idea which tier they need sees the mascot and one large,
clearly labeled button per tier, and picks the one that matches what they're trying to do, rather
than landing straight in the middle of Getting Started's install steps with no orientation.

**Why this priority**: The default landing page shapes every reader's first impression, and a
reader who isn't installing for the first time (someone already running this sandbox, or someone
just browsing) has no reason to land inside Getting Started specifically.

**Independent Test**: Open the site with no URL fragment, see only the full-width hero image and
four large buttons directly beneath it (no headline, no lede, no sidebar, no tier content); click
each button in turn and land on that tier's first page with its normal sidebar restored.

**Acceptance Scenarios**:

1. **Given** the site with no URL fragment, **When** it loads, **Then** the home splash page shows
   the full-width hero image and four large tier buttons directly beneath it, with no headline or
   lede text, not Getting Started's Install page.
2. **Given** the home splash page, **When** a reader clicks a tier's button, **Then** that tier's
   first page loads with its normal sidebar, hero, and pager restored.
3. **Given** any content page, **When** a reader clicks the brand mark in the top navigation,
   **Then** they return to the home splash page.

### Edge Cases

- What happens when a reader's browser has JavaScript disabled? The page shell still loads, but
  reading any actual content requires JavaScript (fetch + render) - a deliberate, accepted
  regression from every prior revision's CSS-only-routing guarantee (see Background). A
  `<noscript>` message MUST point the reader at the content files directly on GitHub instead of
  leaving a blank page with no explanation.
- What happens when a URL fragment names a tier and page that don't exist (a typo, a stale
  bookmark from before a page was renamed)? The router MUST fall back to the home splash page
  rather than showing a blank page, a raw JavaScript error, or guessing which tier the reader
  meant.
- What happens when a URL fragment points at a sub-heading inside a page, not the page's own top
  (a three-segment hash, `#tier/page/heading-id`)? The named page MUST load and the browser MUST
  scroll to that heading once rendering finishes, the same as the old single-file site's
  sub-heading deep links.
- What happens when a `.md` file fails to fetch (a typo in the manifest, a network hiccup, the
  file genuinely missing)? The content area MUST show a clear, specific error naming what failed,
  with a link to the same content read directly on GitHub, rather than a blank page or a raw
  fetch exception.
- What happens when two headings on the same page would produce the same auto-slugified id (two
  headings that happen to share wording)? The router MUST disambiguate automatically (append a
  counter) rather than silently overwriting one heading's anchor with another's; a page's own
  heading that needs a stable, short cross-reference target independent of its exact wording MAY
  pin one explicitly with a trailing `{#exact-id}` (Pandoc/kramdown-style header attribute).
- What happens on a narrow (phone-width) screen? Top navigation and each page's own two-part
  sidebar (its tier's other pages, then "On this page") must remain usable, not clipped,
  overflowing, or overlapping content.
- What happens if GitHub Pages is not yet enabled for this repository? The site's source must be
  fully correct and complete in the repository regardless; enabling Pages itself is a one-time
  repository-settings action outside this repository's own files (documented in this spec's
  Assumptions).
- What happens when a page other than "FAQ" would otherwise need to justify a naming or scoping
  choice that traces back to an earlier repository or tool? That page states the current,
  present-tense fact (the name, the scope, the behavior) and links to "FAQ" for the reasoning,
  which in turn links to its own "Inspiration" entries for the earlier work behind it, rather than
  restating that history itself.
- What happens if a reader pastes an AI-agent prompt into an agent that isn't yet configured (no
  AI CLI installed, no credential set)? The prompt itself doesn't handle that case; every prompt
  assumes "Use AI coding agents safely" (part of "Day to Day") is already done, and each prompt's
  page links there if it isn't the page itself.
- What happens when `docs/vendor/mermaid.min.js` fails to load or a diagram fails to render (a
  network hiccup, a malformed diagram)? That one diagram MUST show a clear, specific error in
  place of the diagram, without blocking the rest of the page's content from rendering.
- What happens on a page with no Mermaid diagram? `docs/vendor/mermaid.min.js` MUST NOT be
  fetched at all - the lazy-load only triggers when a page's rendered content actually contains a
  Mermaid code block.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST include a `docs/` directory whose page *chrome* (navigation,
  CSS, the content router) is one HTML shell, `docs/index.html`, with no build step, no
  static-site generator, and no client-side routing/framework library of any kind beyond the
  vendored libraries FR-018 names - suitable for GitHub Pages' "deploy from a branch" mode pointed
  at `main` / `docs`. Page *content* is plain Markdown, one file per page under
  `docs/content/<tier>/<page>.md` (FR-019); a plain static image asset referenced by an `<img>`
  tag (FR-017's mascot images, FR-022's `docs/logo.png`) is likewise outside the shell itself.
  Together these are the only
  exceptions to "one file" - none of them introduces the build tooling, a JavaScript framework, or
  a live external dependency the "no library/CDN/framework" half of this rule exists to keep out.
- **FR-002**: The site MUST include a `.nojekyll` marker so GitHub Pages serves every file
  (`index.html`, the `.md` content files, `vendor/marked.js`) as-is, without Jekyll processing.
- **FR-003**: Navigation MUST use hash-based URLs of the form `#<tier>/<page>` (optionally
  `#<tier>/<page>/<heading-id>` for a sub-heading), kept in sync with the browser's back/forward
  history and directly bookmarkable/shareable, and MUST update on every navigation without a full
  page reload.
- **FR-004**: The site MUST group its pages into three graduated tiers, in this order in the top
  navigation: **Getting Started** (FR-005), **Day to Day** (FR-006), **Going Further** (FR-007),
  and **FAQ** (FR-008) as a fourth, non-graduated tier. The home splash page (FR-024) is the
  default when no URL fragment is present, or when the fragment names a tier/page that doesn't
  exist.
- **FR-005**: **Getting Started** MUST have exactly two pages: **Install** (Windows/WSL first,
  followed by Linux, then macOS, then a manual/step-by-step equivalent - "just the facts," minimal
  surrounding rationale) and **Verify it worked & your first day** (running `doctor`, the
  Autocomplete UX explanation and both its fixes - a `bleopt` setting or the `fish` persona -
  cloning a first repository, and where to go next). Personas MUST NOT be explained in full here;
  a pointer to Day to Day's personas page is enough, consistent with FR-011's one-canonical-answer
  rule. Neither page carries a large hero graphic (see FR-024); the mascot's hero images live only
  on the home splash page.
- **FR-006**: **Day to Day** MUST have these pages, each genuinely task-shaped: **Combine personas
  for your role** (the persona table, `ws-persona list`/`current`/`activate`/`deactivate`,
  combining and persisting more than one), **Authenticate & manage credentials** (`gh`/`glab`
  OAuth login as the preferred path, the plain credentials file, `GITHUB_TOKEN`/`GITLAB_TOKEN` as
  the secondary path), **Work across multiple git hosts** (`ws-repos`, multi-host `ws-repos.json`,
  `fresh`, `status`, `inspect`, a Mermaid diagram of the `~/workspaces/<git-host>/<org>/<repo>`
  layout `ws-repos` produces), **Stay in sync & recover** (`doctor`, `workspaces-host-update`,
  home-manager generation rollback), **Use AI coding agents safely** (installing the hosted CLIs,
  per-invocation credential scoping, `scaffold-agent-harness`), and **Everyday tools** (shell
  features, `lefthook`, `sensitivectl`, and the rest). Each page's relevant AI-agent prompt(s) MUST
  live on that same page, not in a separate section.
- **FR-007**: **Going Further** MUST have a light number of pages, each a real advanced use case:
  **Personalize with `local.nix`** (a durable `bleopt` tweak, a git-identity override, a
  machine-only package), **Add a tool or write a new persona** (the base-profile-vs-persona
  decision, concrete steps including registering a new persona with `flake.nix` and `ws-persona`),
  **Team secrets with `sops`** (`workspacesHost.secrets`, a full encrypt/declare/apply walkthrough),
  **Container & CI parity** (`oci-image`/`oci-image-sandboxed`, using the same closure in a
  pipeline, the `nix flake check`/scratch-activation validation loop), **Extend the repo with an AI
  agent** (the constitution, the spec-driven workflow, concrete rules for an agent changing this
  repository - this absorbs what the prior "Contributing" section covered), and **How it's built**
  (Nix/flakes/home-manager in plain terms, the repository's file layout, how personas mechanically
  combine, how this site itself works) - reference material that doesn't fit a task shape, kept
  here rather than as a separate nav destination.
- **FR-008**: **FAQ** MUST give the actual reasoning behind every real design decision described
  elsewhere on the site or in the README (at minimum: why this repository exists at all; why
  Nix/home-manager over alternative toolchains; why a plain credentials file; why secrets are
  scoped per invocation; why the AI harness CLIs aren't Nix-packaged; why the base profile stays
  small and personas exist; why fish is a persona rather than the default shell; why `ws-repos` is
  named that; why the v1-roadmap tools - Deno, Lefthook, Tailscale/Nebula - are provisioned the way
  they are; why oh-my-posh doesn't self-update; why there's no Java version manager; why every
  feature gets a spec; why the documentation lives on this site rather than in the README; and why
  this site fetches Markdown instead of staying one static HTML file), and, within the same page
  but visually set apart in its own sidebar group (FR-014), an "Inspiration" set of entries. Every
  other page that makes a "this was deliberate" claim MUST link to that claim's matching FAQ entry.
- **FR-009**: The site MUST share one consistent top navigation (reachable from every page, in the
  same position, without a full page reload between pages) and one consistent visual style, so
  moving between pages never feels like a different site.
- **FR-010**: The site's prose (every `.md` content file) MUST follow
  `.specify/memory/writing-style.md`, per the constitution's Documentation Voice principle.
- **FR-011**: The README MUST stay a short overview (purpose, core concepts, a link to this site)
  rather than a comprehensive walkthrough; this site, not the README, MUST be the comprehensive,
  always-current documentation. A change that affects installation, day-to-day usage, or the
  technical architecture MUST update this site (the relevant `.md` file(s)) in the same commit; the
  README MUST only change when the short overview itself stops being accurate.
- **FR-012**: The site MUST be usable at phone width (no horizontal scrolling of page content;
  navigation and the two-part sidebar remain reachable, wrapping or stacking rather than
  overflowing).
- **FR-013**: Within FAQ (FR-008), an "Inspiration" group of entries MUST name and link every
  earlier repository or tool this project's own lineage includes (a first version of this
  repository, the separate multi-repository tool `ws-repos` takes its pattern from, and a second
  version), framing this repository as their spiritual successor, not a strict port or a promise of
  behavioral compatibility with any of them, and MUST be visually set apart from FAQ's
  design-rationale entries in the page's own sidebar (a distinct labeled group, not interleaved
  with them). Every other page on the site MUST describe this repository entirely on its own,
  present-tense terms, with no reader needing to know any of that history to install, use, or
  understand it; a page whose reasoning traces back to that history MUST link to FAQ's Inspiration
  entries rather than restate the history itself.
- **FR-014**: (Reserved - merged into FR-013's own numbering above to keep the Inspiration
  requirement's cross-references from earlier revisions valid; see FR-013.)
- **FR-015**: Getting Started's "Verify it worked & your first day" page (FR-005) MUST explain why
  bash's typing can feel slow (`blesh`'s default auto-triggering of full completion on almost
  every keystroke) and give both fixes: the exact `bleopt` setting to disable, shown both as a
  live, session-only command and as a durable snippet for `~/.config/workspaces-host/local.nix`;
  and a pointer to Day to Day's personas page for the `fish` persona as the native alternative.
  Day to Day's "Everyday tools" page MUST link to this explanation rather than restate it.
- **FR-016**: (Reserved for the same reason as FR-014 - Autocomplete UX is now FR-015 above.)
- **FR-017**: The repository MUST include the mascot illustration as two cropped images, each with
  real alt/description text (not a bare filename) - not a generic stock graphic, but this
  repository's own: `docs/mascot.jpg` (the hero panel), shown at the top of the home splash page
  (FR-024) and as README.md's own banner image (the same file, not a duplicate); and
  `docs/mascot-workflows.jpg` (the "Workhorse in Action" vignette grid), shown below the home
  splash page's button grid. Neither image appears on any tier or content page (see FR-005/FR-024)
  - the splash page is the only place a reader sees a large graphic. A landscape crop of the hero
  panel MUST exist as `docs/social-preview.jpg`, sized to GitHub's own recommendation for a
  repository's social-preview image, for a human to upload via repository Settings (see
  Assumptions for why that upload step can't be automated).
- **FR-018**: The site MUST render Markdown content client-side using a vendored JavaScript
  library, [marked](https://github.com/markedjs/marked), committed at `docs/vendor/marked.js`
  (with its license at `docs/vendor/marked.LICENSE.txt`) rather than loaded from a live CDN, and
  fetched eagerly (loading it is cheap and every page needs it). A second vendored library,
  [Mermaid](https://mermaid.js.org/), committed at `docs/vendor/mermaid.min.js` (with its license
  at `docs/vendor/mermaid.LICENSE.txt`), renders diagrams on the pages that have one (FR-025);
  unlike marked, it MUST be fetched lazily, only the first time a page's rendered content actually
  contains a Mermaid code block, and cached for the rest of the session once loaded, since the
  file is roughly 5.5MB and most pages have no diagram at all. Both are vendored, not CDN-loaded,
  so the site has no third-party dependency at request time. Bumping either vendored version MUST
  be a deliberate, reviewable file replacement (re-fetch the package, re-copy the browser build),
  never an automatic or silent update.
- **FR-019**: Each page's content MUST be one plain Markdown file at
  `docs/content/<tier>/<page>.md`, readable and reviewable on its own (in a PR diff, or directly on
  GitHub) with no dependency on the HTML shell to make sense as prose. A page's headings MUST get
  their anchor ids automatically, slugified from the heading text, unless the heading pins an
  explicit id with a trailing `{#exact-id}` (used when a stable cross-reference target needs to
  survive a heading-wording edit). A callout (an aside, tip, warning, or note set visually apart
  from body text) MUST be written as a GitHub-style alert blockquote (`> [!TIP]`, `> [!NOTE]`,
  `> [!WARNING]`, `> [!IMPORTANT]`, or `> [!CAUTION]`), which the site converts to its own styled
  callout at render time - chosen specifically because that convention already renders sensibly
  when the same file is read directly on GitHub, unlike a raw HTML `<div>`.
- **FR-020**: Every page's sidebar MUST be one unified, unlabeled list: every page in the same
  tier, with the current page's own headings (generated from its actual rendered `h2`/`h3`
  elements, never hand-maintained) nested directly beneath it as indented sub-items. No "Pages" or
  "On this page" label - the nesting itself, not a heading above each group, is what distinguishes
  a sibling page from a place within the page the reader is already on.
- **FR-021**: Every fenced code block MUST get a "Copy" button after rendering, matching the prior
  single-file site's behavior, re-applied on every navigation (since content is replaced, not
  static).
- **FR-022**: The top navigation's content (the brand mark, the four tier links, the GitHub link)
  MUST be constrained to the same max-width and centered the same way as every page's own content
  (`.page`/`.page-hero`) - not stretched edge to edge - so the nav visually aligns with the content
  beneath it at every viewport width. The brand mark MUST show the project's own logo (the
  icon-only crop, `docs/logo.png`, sized for a small inline mark - not the full badge-with-text
  version, which is illegible at nav-bar scale) next to the plain text "Workspaces Host," never the
  repository slug (`workspaces-host-v3`) - the version qualifier is a technical implementation
  detail, not part of the project's name, and stays out of the one piece of brand-facing text on
  the page.
- **FR-023**: The bottom of every content page (every page within Getting Started, Day to Day,
  Going Further, or FAQ) MUST show a "Previous"/"Next" pager, letting a reader move linearly
  through the site (every page across every tier, in the same order as the top navigation and each
  tier's own page list) without going back to the sidebar or top nav for each step - reading the
  site front to back, the way a book's own page-turning works. Reaching the last page of a tier and
  continuing MUST cross into the first page of the next tier (and the reverse crossing back); the
  very first page overall (Getting Started's Install) MUST show no "Previous," and the very last
  page overall (FAQ) MUST show no "Next," rather than wrapping around or linking to nothing. The
  home splash page (FR-024) is not part of this linear sequence and shows no pager.
- **FR-024**: The site MUST have a home splash page, reachable at an empty URL fragment or the
  explicit `#home`, showing only: the mascot's hero image (`docs/mascot.jpg`), rendered at the
  full width of the page's content column (no headline or lede text - the hero image's own caption
  already carries that), one large button per tier (Getting Started, Day to Day, Going Further,
  FAQ) directly beneath the hero image, linking to that tier's first page, and the "Workhorse in
  Action" image (`docs/mascot-workflows.jpg`) below the button grid. The splash page MUST show no
  sidebar and no "Previous"/"Next" pager - it is not part of any tier's own page list. It MUST be
  the default page (FR-004) and the fallback for any URL fragment that names a tier or page that
  doesn't exist. The top navigation's brand mark MUST link to it.
- **FR-025**: Any content page MAY include a Mermaid diagram, written as a fenced ` ```mermaid `
  code block in that page's Markdown, rendered client-side by FR-018's lazily loaded Mermaid
  library. Diagrams are opt-in per page, not a requirement - a page adds one only where a
  flow, decision, or architecture relationship genuinely benefits from a visual, consistent with
  content pages otherwise staying free of large graphics (FR-017).

### Key Entities

- **`docs/index.html`**: the page shell - navigation, CSS, and the router (manifest, fetch, render,
  TOC generation, callout conversion, code-block enhancement, the home splash page). Contains no
  page content itself.
- **`docs/content/<tier>/<page>.md`**: one plain Markdown file per page - the actual content,
  readable on its own.
- **`docs/vendor/marked.js`**: the vendored Markdown-rendering dependency, loaded eagerly,
  committed rather than CDN-loaded.
- **`docs/vendor/mermaid.min.js`**: the second vendored dependency, diagram rendering, loaded
  lazily only when a page needs it, committed rather than CDN-loaded.
- **The home splash page**: the default landing page (`#home` or an empty/unrecognized fragment) -
  the mascot's hero image, a lede, one large button per tier, and the "Workhorse in Action" image.
  Not part of any tier's own page list.
- **Getting Started / Day to Day / Going Further**: the three graduated tiers, each a `.md` file
  per page under `docs/content/`, use-case driven rather than topic-organized.
- **FAQ**: the fourth, non-graduated tier - the "why" layer every other tier links into.
  "Inspiration" lives inside it, visually set apart from its design-rationale entries.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reader following only Getting Started's Install page's WSL subsection reaches a
  working shell with no need to consult any other page.
- **SC-002**: Every tier is reachable from every other tier in exactly one click, and every page
  within a tier is reachable from that tier's sidebar in exactly one further click, with no full
  page reload.
- **SC-003**: The site works with no network access beyond loading `docs/index.html`,
  `docs/vendor/marked.js`, `docs/logo.png`, and either: the home splash page's own two mascot
  images, or (any content page) the one Markdown content file for the page being viewed plus
  `docs/vendor/mermaid.min.js` only if that page actually has a Mermaid diagram - no external
  font/script/stylesheet dependency, no live CDN, nothing fetched from a third-party host at
  request time. JavaScript IS required to read content (a deliberate, documented departure from
  every prior revision's guarantee; see Background).
- **SC-008**: Opening the site with no URL fragment (or an unrecognized one) shows the home splash
  page, not any tier's content, with no sidebar and no pager; clicking any of its four buttons
  reaches that tier's first page with its normal sidebar, hero, and pager restored - verified as an
  actual click-through, not just read off the manifest.
- **SC-009**: A page with no Mermaid diagram never triggers a `docs/vendor/mermaid.min.js` request;
  a page that has one renders it as a real SVG with no console error, verified directly in a
  browser, not assumed from the Markdown source alone.
- **SC-004**: Every "this was deliberate" claim elsewhere on the site links to a real, substantive
  answer in FAQ, not a restatement of the same sentence.
- **SC-005**: A reader with no prior knowledge of any earlier repository or tool this project grew
  out of can read every tier, and every part of FAQ except its Inspiration group, and complete
  every task those pages describe with no gap in understanding; Inspiration is the only part of
  the site that names or links that earlier work.
- **SC-006**: Every internal cross-reference link (every `#tier/page` and `#tier/page/heading-id`
  href across every `.md` file) resolves to a real page and, where a heading id is named, a real
  heading on that page - verified directly, not assumed, since nothing else enforces this once
  content lives in separate files.
- **SC-007**: Starting at Getting Started's Install page and clicking only "Next" reaches every
  page on the site exactly once, in nav order, ending at FAQ with no "Next" left to click -
  verified as an actual click-through, not just read off the manifest.

## Assumptions

- Enabling GitHub Pages itself (repository Settings → Pages → source: Deploy from a branch → `main`
  / `docs`) is a one-time, human, repository-settings action this spec's files cannot perform -
  outside what any file in this repository can configure.
- Setting the repository's social-preview image (Settings → General → Social preview → Edit →
  Upload an image) is the same category of one-time, human, repository-settings action - GitHub
  exposes no API for it, so `docs/social-preview.jpg` (FR-017) exists in the repository ready to
  upload, but the upload step itself is outside what any file here can perform.
- The site's content is derived from, and MUST stay consistent with, this repository's specs and
  actual behavior; it does not introduce any capability the flake itself doesn't already have.
- The reader's browser has JavaScript enabled to read content (see Background and SC-003) and
  supports the `fetch` API, template literals, and `Array.prototype.forEach` on a `NodeList` -
  universal in actively updated Chrome, Edge, Safari, and Firefox as of this writing. A browser
  old enough to lack these is out of scope, the same way this repository doesn't target
  unsupported OS versions elsewhere.
