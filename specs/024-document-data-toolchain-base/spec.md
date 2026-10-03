# Feature Specification: Document/Data Toolchain in the Base Profile

**Feature Branch**: `024-document-data-toolchain-base`

**Created**: 2026-10-03

**Status**: Implemented

**Input**: User description: "Every Intellectual Frontiers repo is moving to 'no setup step after
clone' - the `eidolon` repo currently installs a document/data Python toolchain (RDF, SHACL, PDF,
spreadsheet, font tooling) via pip. That has to come from this flake instead, so IF repos can
delete their install targets."

## Background

`home/ai-harness.nix` already provisions a bare `python3` (for `uvx`-launched MCP servers) and
`uv`. Several Intellectual Frontiers repositories (`eidolon` named explicitly) currently `pip
install` a small, broadly-reusable set of document/data libraries on top of that at clone time -
exactly the kind of imperative, per-repo setup step the "no setup step after clone, everything
runs in workspaces-host-v3" rule exists to eliminate. These libraries (RDF graph handling, SHACL
validation, HTML parsing, YAML, image/PDF/spreadsheet manipulation, font tooling, and the
Playwright Python binding) are general-purpose enough, and small enough combined, to belong in the
base profile rather than a persona - every engineer gets them, the same way `jq`/`duckdb`/`sqlite3`
already are base-profile tools for adjacent reasons.

Two of the requested packages, `pyshacl` and its own dependency `owlrl`, are not packaged in
nixpkgs (checked against this flake's pinned nixos-25.05 revision) - a real gap, not a packaging
oversight, confirmed by searching nixpkgs' python3Packages set directly. Both ship a small,
dependency-light, pure-Python universal wheel on PyPI, so they're vendored the same way this
repository already vendors `specify-cli` (pkgs/specify-cli) when something it needs isn't in
nixpkgs: a `pkgs/<name>/default.nix` using `buildPythonPackage`, installing the published wheel
directly (no build backend to detect - simpler than building from the sdist for zero benefit).

A single `python3.withPackages` environment is the only way to combine these with the bare
`python3` interpreter home/ai-harness.nix's `uv`/MCP-server use case already needs: two different
derivations both trying to provide `bin/python3` in `home.packages` would collide at build time
(a `buildEnv` priority conflict), so the existing bare `pkgs.python3` entry in home/ai-harness.nix
moves into this one combined environment instead of staying separate.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A document/data script just runs (Priority: P1)

An engineer or AI agent working in an IF repository that needs RDF/SHACL/PDF/spreadsheet/font
tooling runs that repository's own Python script with no `pip install` step first, on every
flavor this flake produces (bare-metal, VM, OCI image, devcontainer, cloud agent session).

**Why this priority**: This is the concrete instance of "no setup step after clone" for the
document/data tooling `eidolon` and similar repos already depend on.

**Independent Test**: In a freshly built/pulled environment with no extra install step,
`python3 -c 'import rdflib, pyshacl, html5lib, yaml, PIL, pypdf, reportlab, openpyxl, pdfplumber,
fontTools, playwright'` exits 0.

**Acceptance Scenarios**:

1. **Given** the base profile (no persona activated), **When** the above import line runs,
   **Then** every module imports successfully.
2. **Given** the same environment, **When** `uv`/`uvx`-launched MCP servers and `aider`/the AI CLIs
   (home/ai-harness.nix's existing use of `python3`) are exercised, **Then** they continue to work
   unchanged - this profile's `python3` is still a complete, ordinary interpreter, just with more
   site-packages installed.

### Edge Cases

- `rdflib`'s own optional `[html]` extra (`html5rdf`, for parsing RDFa/microdata embedded in HTML)
  is deliberately NOT pulled in as part of satisfying `pyshacl`'s dependency graph - pyshacl only
  imports it lazily when actually asked to parse HTML-embedded RDF, so it isn't needed for the
  import-level acceptance test above, and this base profile already carries plain `html5lib` (a
  different, older library) for its own, unrelated reason.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The base profile MUST provide a single `python3.withPackages` environment containing
  `rdflib`, `pyshacl`, `html5lib`, `pyyaml`, `pillow`, `pypdf`, `reportlab`, `openpyxl`,
  `pdfplumber`, `fonttools`, and the `playwright` Python binding, replacing the bare `python3`
  entry home/ai-harness.nix previously provisioned.
- **FR-002**: `pyshacl` and `owlrl` (pyshacl's own direct dependency), neither packaged in
  nixpkgs, MUST be vendored as `pkgs/pyshacl` and `pkgs/owlrl` respectively, each installing its
  published PyPI wheel via `buildPythonPackage`, and exposed through `pkgs/default.nix` like every
  other custom-built tool in this repository.
- **FR-003**: `doctor` MUST check that the full import line (FR-001's module list) succeeds.
- **FR-004**: `uv` remains a separate base-profile package (home/ai-harness.nix); only the bare
  `python3` entry is superseded by FR-001's combined environment.

### Key Entities

- **`home/tools.nix`**: where the combined `python3.withPackages` environment is declared (the
  general "everyday, broadly useful" module, the same place `duckdb`/`sqlite3` already live for an
  analogous reason).
- **`pkgs/owlrl`, `pkgs/pyshacl`**: the two vendored packages FR-002 adds.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The acceptance test's import line succeeds on every flavor `nix flake check
  --all-systems` evaluates, and on a real built/pulled OCI image.
- **SC-002**: No IF repository needs its own `pip install`/`requirements.txt` step for this
  package list after adopting this flake.

## Assumptions

- `playwright` here is nixpkgs' Python binding (`python3Packages.playwright`), version-locked by
  nixpkgs to the same revision as `playwright-driver.browsers`/`playwright-test` already in
  home/ai-harness.nix (confirmed: all three sit at 1.52.0 against this flake's pinned nixpkgs) -
  not a new, independently-tracked browser automation stack.
