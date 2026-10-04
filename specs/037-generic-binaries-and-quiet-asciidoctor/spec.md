# Feature Specification: Generic Linux Binaries Run in the Images, and asciidoctor Runs Silently

**Feature Branch**: `037-generic-binaries-and-quiet-asciidoctor`

**Created**: 2026-10-04

**Status**: Implemented

**Input**: Fresh-machine acceptance test of the `eidolon` vault against
`workspaces-host-press:sha-8efca19` (report on its `verify/eid-manifest` branch). The package lists
were fine. The image's runtime wiring failed three vault commands: `eid fresh` (Pillow's wheel
dlopens libfribidi for raqm text layout, and the image has none on the library path),
`eid console check` (the `playwright==1.50.0` wheel's greenlet needs `libstdc++.so.6`, which the
image carries but not on the loader path), and the same wheel's bundled `driver/node`, a generic
glibc ELF whose interpreter `/lib64/ld-linux-x86-64.so.2` does not exist here. Also: every
`asciidoctor` run printed a Bundler warning on stderr.

## Background

The images have no FHS. That's deliberate, and it's why a generic Linux binary or wheel falls over
in them in three different ways. A binary whose ELF interpreter is `/lib64/ld-linux-x86-64.so.2`
can't even start. A wheel loaded into a nix-built Python never passes through any loader but that
Python's own, so it only finds a system library through `LD_LIBRARY_PATH`. And a wheel that dlopens
a library by name finds nothing, because there is no `ld.so.cache`. I don't want people reading
that as "the image can't run wheels". A pip or uv install should work here the way it does on an
ordinary Linux box, and nothing in the image should hide what it does to get there.

Two pieces, because there are two mechanisms. nix-ld goes at the loader path generic binaries name.
It hands control to the image's glibc loader with `NIX_LD_LIBRARY_PATH`, so a generic binary gets a
sensible library set and no nix-built program's library choice changes. `LD_LIBRARY_PATH` carries a
small set (libstdc++ and libgcc_s, zlib, fribidi, harfbuzz, freetype) for the other case, a wheel
inside a nix-built interpreter, which nix-ld never sees. I kept that set small on purpose:
`LD_LIBRARY_PATH` wins over a nix binary's RUNPATH. I checked that `ldd` resolves exactly the same
libraries with and without it for xetex, luahbtex, rsvg-convert, pdftotext, magick, java, node,
ruby, python3 and qpdf.

The warning came from RubyGems, not from the gem set. nixpkgs' asciidoctor binstubs set `GEM_HOME`
but not `GEM_PATH`, so RubyGems also scans ruby's own gem directory. Ruby 3.3's bundled `rbs`,
`racc` and `debug` live there with no built extensions in nixpkgs' ruby, and Bundler complains about
each. The gem set is complete (it has its own, newer `racc`), so the press persona wraps the
executables with `GEM_PATH` set to the gem set alone. That's what nixpkgs' own `bundlerApp` does for
`scripts`. No extension is built and nothing is hidden: the three stubs just stop being searched.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A uv-installed wheel works in the image (Priority: P1)

**Independent Test**: In the press image, in a throwaway `uv venv`, `uv pip install pillow
playwright==1.50.0` then run the commands in the acceptance scenarios, once with the uv-managed
Python and once with the image's own (`--python /bin/python3`).

**Acceptance Scenarios**:

1. **Given** a Pillow wheel, **When** `python -c "import PIL.features as f; print(f.check('raqm'))"`
   runs, **Then** it prints `True`.
2. **Given** `playwright==1.50.0`, **When** `python -c "import playwright.sync_api"` runs, **Then**
   it succeeds, and `playwright --version` prints `Version 1.50.0`.
3. **Given** that wheel, **When** its bundled `driver/node --version` runs, **Then** it starts.

### User Story 2 - asciidoctor prints nothing it shouldn't (Priority: P2)

**Independent Test**: `asciidoctor --version 2>err; wc -c <err` prints 0 in the press image.

**Acceptance Scenarios**:

1. **Given** the press image, **When** `asciidoctor`, `asciidoctor-pdf` or `asciidoctor-epub3` runs,
   **Then** stderr is empty on success.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every published image MUST provide an executable nix-ld at the loader path generic
  binaries of its architecture name (`/lib64/ld-linux-x86-64.so.2` on x86_64,
  `/lib/ld-linux-aarch64.so.1` on aarch64), and MUST set `NIX_LD` to the image's glibc loader and
  `NIX_LD_LIBRARY_PATH` to a library set that includes libstdc++, libgcc_s, zlib, fribidi,
  harfbuzz and freetype.
- **FR-002**: Every published image MUST set `LD_LIBRARY_PATH` to exactly libstdc++/libgcc_s, zlib,
  fribidi, harfbuzz and freetype, so a wheel loaded into a nix-built interpreter finds them.
- **FR-003**: Setting `LD_LIBRARY_PATH` MUST NOT change which libraries a nix-built program in the
  image resolves.
- **FR-004**: The `press` persona MUST run `asciidoctor-with-extensions` with `GEM_PATH` set to its
  gem set alone, so the executables write nothing to stderr on success.
- **FR-005**: `doctor` MUST, where `NIX_LD` is set, FAIL if the generic loader path is not
  executable, if `NIX_LD` is not an executable file, or if `libstdc++.so.6` is not on
  `LD_LIBRARY_PATH`.

## Success Criteria *(mandatory)*

- **SC-001**: In the press image, the User Story 1 scenarios pass with both Pythons.
- **SC-002**: In the press image, `asciidoctor`, `asciidoctor-pdf` and `asciidoctor-epub3` produce
  a document with 0 bytes on stderr.
- **SC-003**: `ldd` of the press image's nix-built binaries shows the same libraries with and
  without `LD_LIBRARY_PATH`.

## Assumptions

- A wheel that needs a library outside the FR-001 set isn't covered; the set is the common one,
  not every one.
- The rust and base images get FR-001 and FR-002 from the same `oci/default.nix`; I verified them
  on the press image only.
