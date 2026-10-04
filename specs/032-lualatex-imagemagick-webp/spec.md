# Feature Specification: LuaLaTeX in `press`; ImageMagick with WebP Everywhere

**Feature Branch**: `032-lualatex-imagemagick-webp`

**Created**: 2026-10-04

**Status**: Implemented

**Input**: User description: "In `press`: the LuaLaTeX collection. `.github`'s print harness fails
with `! LaTeX Error: File 'lualatex-math.sty' not found.` Add the collection Debian calls
`texlive-luatex`: at least `lualatex-math`, `luaotfload`, and `fontspec`/`unicode-math` working
under LuaLaTeX. ImageMagick built with WebP, plus `libwebp`'s `cwebp`/`dwebp`. `.github`'s imagery
harness fails on the missing `identify`. Base profile, or `press`; your call."

## Background

`lualatex` was already on PATH in the press image; it comes with the XeLaTeX collections. What was
missing were LuaLaTeX's own packages, so a document stopped at `lualatex-math.sty`. TeX Live's
`collection-luatex` is what Debian packages as `texlive-luatex`, and adding it to press's
`texlive.combine` is the whole fix. `luaotfload` writes a font cache on first run; TeX Live puts
that under `~/.texlive<year>/`, which is writable, so no variable is needed.

ImageMagick and libwebp go in the base profile, not press. An image pipeline (resize a brand's
imagery, write a WebP share card) has nothing to do with typesetting, and the IF repos that need
it don't all use press. nixpkgs' `imagemagick` is built with libwebp by default; `doctor` checks
the format list rather than trust that.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A LuaLaTeX document compiles in press (Priority: P1)

**Independent Test**: In the press image, `lualatex` compiles a document loading `fontspec`,
`unicode-math` and `lualatex-math`.

### User Story 2 - An imagery harness runs in any image (Priority: P1)

**Independent Test**: In every image, `magick -list format` lists WEBP as read/write, and
`magick in.png out.webp`, `identify out.webp`, `cwebp` and `dwebp` all work.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `press` persona's TeX Live MUST include `collection-luatex`.
- **FR-002**: Under `lualatex` in the press image, `fontspec`, `unicode-math`, `lualatex-math` and
  `luaotfload` MUST load and a document using them MUST compile.
- **FR-003**: The base profile MUST provide ImageMagick (`magick`, `identify`, `convert`) built
  with WebP read and write support, and libwebp's `cwebp` and `dwebp`.
- **FR-004**: `doctor` MUST check `magick identify convert cwebp dwebp` in its default output, FAIL
  if ImageMagick cannot read and write WebP, and, when `lualatex` is present, FAIL if `kpsewhich`
  cannot find `lualatex-math.sty`, `luaotfload.sty`, `fontspec.sty` or `unicode-math.sty`.

## Success Criteria *(mandatory)*

- **SC-001**: `.github`'s `tools/run_assurance.sh` gets past `lualatex-math.sty` and `identify` in
  the press image.
