# Feature Specification: A Standard Unix Userland in Every Image

**Feature Branch**: `030-standard-unix-userland`

**Created**: 2026-10-04

**Status**: Implemented

**Input**: User description: "Still missing in all three images at `sha-516c77c`: sed find xargs
diff cmp patch tar gzip unzip zip bzip2 xz file less which ps hostname tput rsync bc. `eidolon`'s
book build stops at `sed: command not found`, so its CI still builds books on a stock runner. Add
them to the images' contents, or to the base profile so every flavor has them. Have `doctor`
check the set."

## Background

The published images have no base OS. Every tool in them comes from the profile's closure, plus
the handful `oci/default.nix` adds (coreutils, grep, gawk, `/usr/bin/env`). That was fine until a
real build script ran in one: `eidolon`'s `tools/render/build.sh` stopped at its first `sed`. I
checked `sha-516c77c` directly; the press image happened to carry `sed`/`find`/`diff`/`patch`
through TeX Live's dependencies, and still lacked `tar`, `gzip`, `xz`, `file`, `ps`, `which`,
`rsync` and the rest. The base and rust images lacked more.

I put the set in the base profile (`home/tools.nix`), not only the image's extra contents. Host and
image share one closure (Constitution Principle IV), so a tool a build script needs belongs where
both get it. It's Linux-only, except `xz`. Every Linux host already has these from its distro, and
the Nix copies are the same GNU tools. A Mac ships BSD versions of everything but `xz`, and GNU
`sed`/`find`/`tar` ahead of them on PATH would quietly change how existing scripts there behave
(`sed -i ''` is the classic one). `hostname` comes from `hostname-debian`, not `inetutils`:
inetutils also brings an unprivileged `ping` and `traceroute` that would shadow a host's working
setuid ones.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A build script runs in the image unchanged (Priority: P1)

A repository's CI job runs inside a published image and calls ordinary Unix tools.

**Independent Test**: In each published image, with no variable set, `bash -lc 'command -v <tool>'`
succeeds for every tool in FR-001.

**Acceptance Scenarios**:

1. **Given** any of the three published images, **When** a script calls any tool in FR-001,
   **Then** it runs instead of failing with "command not found".
2. **Given** a host or image missing any tool in FR-001, **When** `doctor` runs, **Then** it
   reports a FAIL naming each missing tool.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The base profile MUST provide, on Linux, `sed find xargs diff cmp patch tar gzip
  unzip zip bzip2 xz file less which ps hostname tput rsync bc` (packages `gnused findutils
  diffutils gnupatch gnutar gzip unzip zip bzip2 xz file less which procps hostname-debian ncurses
  rsync bc`), and `xz` on every system.
- **FR-002**: Every published image MUST therefore carry the FR-001 set, since each is built from
  the base profile.
- **FR-003**: The base profile MUST NOT add GNU replacements for BSD tools on Darwin.
- **FR-004**: `doctor` MUST check every FR-001 tool, plus `grep` and `awk`, in its default
  (essential) output, and FAIL naming each one missing.

## Success Criteria *(mandatory)*

- **SC-001**: The `command -v` loop over FR-001 prints no `MISSING` line in any published image.
- **SC-002**: `doctor` in each image passes its "Standard Unix userland" check.

## Assumptions

- A Linux host's distro tools and the Nix-provided GNU tools behave the same, so putting the Nix
  ones first on PATH changes nothing a script can observe beyond version.
