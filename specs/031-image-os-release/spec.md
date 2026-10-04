# Feature Specification: `/etc/os-release` in Every Image

**Feature Branch**: `031-image-os-release`

**Created**: 2026-10-04

**Status**: Implemented

**Input**: User description: "Still missing. The devcontainer CLI reads it on `up` and logs
`Command in container failed: (cat /etc/os-release || cat /usr/lib/os-release)`, and VS Code's
server and devcontainer features read it too. Add a minimal one (`ID`, `NAME`, `VERSION_ID` = the
short commit) to every image."

## Background

A `dockerTools` image starts from nothing, so there was no os-release(5) file at either place the
spec names. The devcontainer CLI logged a failed command on every `up`.

The file claims no distribution. `ID=workspaces-host` and no `ID_LIKE`: a devcontainer feature
that sees `ID_LIKE=debian` would run `apt-get`, which isn't here. Failing to recognize the OS is
the better failure. `VERSION_ID` is the short commit the image was built from, the same seven
characters CI's `git rev-parse --short HEAD` puts in the `sha-` tag, so you can tell from inside a
running container which tag you're on. Both files are real files, not symlinks into the store,
for the same "path escapes from parent" reason `/etc/passwd` already is (spec 021).

`doctor` uses the file too. Inside an image, a missing `nix` is expected (the image carries the
profile's closure, not Nix), so it's a WARN there instead of the FAIL it is on a host. Before this,
`doctor` in every published image exited 1 on that one line.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tools that read os-release work (Priority: P1)

**Independent Test**: `docker run --rm <image> cat /etc/os-release` prints the fields in FR-002;
`devcontainer up` against the image logs no failed `cat /etc/os-release`.

**Acceptance Scenarios**:

1. **Given** any published image, **When** something reads `/etc/os-release` or
   `/usr/lib/os-release`, **Then** it gets the FR-002 fields.
2. **Given** a published image, **When** `doctor` runs, **Then** a missing `nix` is a WARN, not a
   FAIL.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every image built by `oci/default.nix` MUST contain `/etc/os-release` and
  `/usr/lib/os-release` as regular files with identical content.
- **FR-002**: The file MUST set `ID=workspaces-host`, `NAME`, `VERSION_ID` (the flake's short
  revision, or its dirty short revision for an uncommitted tree), `VERSION`, `PRETTY_NAME`,
  `VARIANT_ID` (`base`, `press` or `rust`) and `HOME_URL`, and MUST NOT set `ID_LIKE`.
- **FR-003**: `doctor` MUST report a missing `nix` as a WARN, not a FAIL, when `/etc/os-release`
  has `ID=workspaces-host`.

## Success Criteria *(mandatory)*

- **SC-001**: `VERSION_ID` in an image published as `sha-<x>` is `<x>`.
- **SC-002**: `doctor` exits 0 in each published image with no variable set.
