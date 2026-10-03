# Feature Specification: Dual-Image, Multi-Arch Publish

**Feature Branch**: `027-dual-image-multiarch-publish`

**Created**: 2026-10-03

**Status**: Implemented

**Input**: User description: "Publish both the base image and a press-persona image, each for
linux/amd64 and linux/arm64, from the same workflow run, with matching `sha-` tags - most
non-technical Mac users are on Apple Silicon, and emulated amd64 is too slow to be the default."

## Background

Spec 020's publish workflow builds and pushes one image (`workspaces-host-v3`), amd64 only, on
`ubuntu-latest` (an amd64 GitHub-hosted runner). Two gaps, now that every Intellectual Frontiers
repository is adopting "this image, no setup step, in every flavor":

1. **Only one image.** Spec 025/026 add the `press` persona; baking it into the one published
   image would cost every devcontainer/Codespace user the download weight of a full TeX Live
   install whether they typeset anything or not. A second image
   (`workspaces-host-v3-press` = base + fish + press, spec 023's `oci-image-press` package) lets an
   IF repo that actually needs it pull a purpose-built image instead.
2. **amd64 only.** A non-technical macOS user - the exact audience Codespaces/"Reopen in Container"
   targets - is overwhelmingly on Apple Silicon (arm64) today. Running an amd64 image under
   emulation works but is slow enough to undermine "instant," so it can't be the only option.

GitHub now provides free, GA, Linux arm64-hosted runners for public repositories
(`ubuntu-24.04-arm`/`ubuntu-22.04-arm`, no special enablement needed on a public repo) - this
repository is public, so a native arm64 build is simply a second matrix leg on a different runner
label, not cross-compilation or QEMU emulation. Nix's own derivation model makes this
straightforward for everything this flake builds: resolving `nix build .#oci-image` on an
`aarch64-linux` runner resolves `packages.aarch64-linux.oci-image` automatically (the Nix CLI infers
`system` from `builtins.currentSystem`), and every package involved - including `press`'s TeX
Live/JRE/epubcheck closure - was confirmed to already have prebuilt `aarch64-linux` substitutes on
`cache.nixos.org` (nixpkgs' stable channels build these widely-used packages for every major
platform; nothing here needs a from-source compile unique to this flake).

A single published tag naming one platform's digest isn't portable - `docker pull
.../workspaces-host-v3:latest` on an Apple Silicon Mac would otherwise silently pull (and emulate)
the amd64 image. The standard fix is a multi-arch **manifest list**: one tag, two platform-specific
digests underneath it, and the client's own Docker/OCI runtime picks the one matching its host
automatically - exactly what "every `sha-` tag works correctly on both architectures" means in
practice, not two separate human-facing tags to choose between.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pull the right image, right architecture, automatically (Priority: P2)

An engineer (Intel or Apple Silicon Mac, amd64 or arm64 Linux) runs `docker pull
ghcr.io/intellectual-frontiers/workspaces-host-v3:sha-<short>` (or `-press`), and gets a native
image for their own machine with no platform flag and no emulation.

**Why this priority**: This is what makes the published image actually fast for the audience this
whole effort targets - a non-technical user on Apple Silicon, specifically.

**Independent Test**: Pull the same tag on both an amd64 and an arm64 host; `docker inspect`
confirms each got a native-architecture image, not an emulated one.

**Acceptance Scenarios**:

1. **Given** a successful publish workflow run, **When** `docker pull
   ghcr.io/intellectual-frontiers/workspaces-host-v3:sha-<short-sha>` runs on an amd64 host,
   **Then** it receives a native linux/amd64 image.
2. **Given** the same run, **When** the same pull command runs on an arm64 host, **Then** it
   receives a native linux/arm64 image - no `--platform` flag needed.
3. **Given** the same run, **When** the equivalent `workspaces-host-v3-press` pulls happen,
   **Then** the same holds for the press image.

### Edge Cases

- A GHCR package defaults to private on its first-ever push (spec 020's own documented one-time
  step for the base image) - `workspaces-host-v3-press` needs that same one-time visibility change
  the first time this workflow publishes it.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `flake.nix` MUST expose `packages.<system>.oci-image-press` (base + fish + press),
  built from the same `oci/default.nix` definition as `oci-image` (parameterized by an
  `imageName` argument so the two don't collide when both are `docker load`ed in one job).
- **FR-002**: `.github/workflows/container-image.yml` MUST build both images
  (`oci-image`/`oci-image-press`) for both `linux/amd64` (`ubuntu-latest`) and `linux/arm64`
  (`ubuntu-24.04-arm`), as a build matrix - four build legs total, each pushing its own
  architecture-suffixed intermediate tag.
- **FR-003**: After both architectures of a given image finish, a merge step MUST publish a
  multi-arch manifest list under that image's `latest` and `sha-<short-sha>` tags, combining the
  `amd64`/`arm64` intermediate tags - the same two human-facing tags spec 020 already documents,
  now resolving correctly on either architecture.
- **FR-004**: Spec 020 MUST be amended to document that every publish produces matching `sha-`
  tags for both images, each a multi-arch manifest list valid on both architectures - not two
  separate per-architecture tags a consumer has to choose between.
- **FR-005**: The documentation book's `container-ci` chapter MUST document the second image and
  multi-arch support.

### Key Entities

- **`.github/workflows/container-image.yml`**: rewritten as a build-matrix-plus-merge workflow.
- **`packages.<system>.oci-image-press`**: the new flake output FR-001 adds.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A single workflow run produces four architecture-specific pushes (2 images × 2
  architectures) and two manifest-list merges (one per image), all under the same commit's
  `sha-<short-sha>`.
- **SC-002**: `docker pull` of either image's `sha-<short-sha>` tag returns a native image on both
  amd64 and arm64 hosts, verified directly against the real published tags, not only a local
  build.

## Assumptions

- `media` (spec 026) is intentionally excluded from both images (see that spec's own Edge Cases) -
  this spec's "both images" always means `oci-image`/`oci-image-press`, never a third.
- The per-architecture intermediate tags (`sha-<short>-amd64`/`sha-<short>-arm64`) are an
  implementation detail of the publish pipeline, not a documented, human-facing interface - a
  consumer always uses the plain `latest`/`sha-<short-sha>` tag, which resolves correctly either
  way via the manifest list.
