# Feature Specification: Public Container Image

**Feature Branch**: `020-public-container-image`

**Created**: 2026-10-03

**Status**: Implemented

**Input**: User description: "Since this is a public repo, publish a continuously-updated public
container image to ease testing, for both humans and AI agents"

## Background

This repository already builds an OCI image (`packages.<system>.oci-image`, spec 005) from the
exact same evaluated home-manager configuration as the host profile - Constitution Principle IV's
container parity. Until now that image only ever existed as a local `nix build` artifact: anyone
who wanted to test against it had to clone the repository and build it themselves, even though the
repository itself is public. A public, continuously-published image removes that step entirely -
`docker pull` and go - for exactly the two audiences who benefit from a disposable, known-good copy
of this environment: an engineer testing a change without touching their own machine, and an AI
agent that wants a sandbox matching this repository's exact closure (the same promise the book's
own `ai-agents` chapter already makes for the AI-harness tooling itself, FR-007's browser-automation
runtime included).

GitHub Container Registry (GHCR) was chosen over Docker Hub: it's free for a public image attached
to a public repository, needs no new secret (the workflow's own `GITHUB_TOKEN` has enough scope to
push), and keeps the artifact next to the source it was built from.

### Why build time and image size don't need trimming here

The image now carries the full base profile, browser-automation packages (spec 008 FR-007)
included - noticeably larger than a minimal container. Two things make that an acceptable
trade-off rather than a problem to solve: GitHub Actions is free and effectively unlimited for
public repositories, and this image rebuilds only on a push to `main` that actually touches
`home/`, `pkgs/`, `oci/`, or the flake itself - infrequent, and since nixpkgs substitutes most of
that closure as prebuilt binaries from `cache.nixos.org` rather than compiling it, a rebuild is
mostly download time, not compute. Pull size is a real, recurring cost for whoever tests with the
image, but Docker's layer cache makes that a one-time cost per machine, not a cost paid on every
pull - so the full, honest image stays simpler than maintaining a second, trimmed variant (Principle
V: the simplest design that satisfies the need today).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pull instead of build, to test a change (Priority: P2)

A human testing a change to this repository (or evaluating it for the first time) runs `docker
pull` and `docker run` against a published tag instead of cloning the repository and running `nix
build` themselves.

**Why this priority**: Directly serves this repository's own stated purpose - "ease testing" - for
anyone, not only engineers already set up to build with Nix.

**Independent Test**: On a machine with only Docker installed (no Nix, no clone of this
repository), run `docker pull ghcr.io/intellectual-frontiers/workspaces-host-v3:latest` and `docker
run -it` against it, and confirm the same shell/tools an activated base profile provides are there.

**Acceptance Scenarios**:

1. **Given** a push to `main` that touches `home/`, `pkgs/`, `oci/`, `flake.nix`, or
   `flake.lock`, **When** the publish workflow runs, **Then** `ghcr.io/intellectual-
   frontiers/workspaces-host-v3:latest` and a `:sha-<short-sha>` tag are both pushed, built from
   that exact commit.
2. **Given** a push to `main` that touches none of those paths (e.g. a docs-only change), **When**
   the workflow's path filter evaluates, **Then** no image is rebuilt or republished.

### User Story 2 - An AI agent grabs a disposable sandbox (Priority: P3)

An AI coding agent (or an engineer scripting one) pulls the published image to get a sandbox that
already matches this repository's exact tool versions, without cloning the repository or running
Nix at all.

**Independent Test**: Documented in the book's `container-ci` chapter and this repository's
README, in language an agent reading either file would act on directly (the exact `docker pull`/
`docker run` commands, not a description of them).

**Acceptance Scenarios**:

1. **Given** the published image, **When** an agent runs `docker run --rm
   ghcr.io/intellectual-frontiers/workspaces-host-v3:latest doctor --all`, **Then** it gets a
   real, authoritative health-check report with no setup step beyond the pull.

### Edge Cases

- What happens on the very first publish, before any human has made the GHCR package public? GHCR
  packages are private by default even when pushed from a public repository's workflow; a repo
  maintainer must visit the package's settings once (Package settings -> Danger Zone -> Change
  visibility -> Public) after the first successful run. This is a one-time, documented manual
  step (see Assumptions), the same shape as spec 019's "set Pages source to GitHub Actions"
  one-time prerequisite.
- What happens if the image build fails (e.g. a nixpkgs substituter is down)? The workflow fails
  and nothing is pushed; the previous `:latest` tag stays exactly as it was, so a transient CI
  failure never leaves a half-published or broken image live.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A GitHub Actions workflow MUST build `packages.x86_64-linux.oci-image` and publish
  it to `ghcr.io/<owner>/<repo>` on every push to `main` that touches `home/`, `pkgs/`, `oci/`,
  `flake.nix`, or `flake.lock`, plus on manual dispatch.
- **FR-002**: Each publish MUST push two tags built from the same image: `latest` and
  `sha-<short-commit-sha>`, so a consumer can pin to an exact, reproducible build instead of only
  ever tracking the moving `latest` tag.
- **FR-003**: The workflow MUST authenticate to GHCR using the workflow's own `GITHUB_TOKEN`
  (`packages: write` permission) - no additional secret to provision or rotate.
- **FR-004**: README MUST document the published image (pull command, what it is) in language
  both a human and an AI agent reading the repository would act on directly.
- **FR-005**: The documentation book's `container-ci` chapter MUST document the published image as
  an alternative to `nix build .#oci-image`, including the exact `docker pull`/`docker run`
  commands, and MUST note the one-time manual step to make the GHCR package public.

### Key Entities

- **`ghcr.io/intellectual-frontiers/workspaces-host-v3`**: the published image, built from
  `packages.x86_64-linux.oci-image` - the same closure `nix build .#oci-image` produces locally.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A machine with only Docker installed can run this repository's base profile via
  `docker pull`/`docker run`, with zero Nix install and zero git clone.
- **SC-002**: A published tag is reproducibly tied to the exact commit it was built from
  (`sha-<short-sha>`), not only a floating `latest`.

## Assumptions

- Only `packages.x86_64-linux.oci-image` is published (not the sandboxed variant). An
  `aarch64-linux`/multi-arch manifest was a real future improvement, left for if/when it's actually
  needed (Principle V) - **superseded by spec 027**, below.
- Making the GHCR package public, and linking it to this repository so it shows up in the
  repository's own sidebar, is a one-time manual step a maintainer performs after the first
  successful run - GitHub does not currently expose a way to set a package's initial visibility
  from a workflow's own `GITHUB_TOKEN`. **Spec 027's second image (`workspaces-host-v3-press`)
  needs this same one-time step on its own first publish.**

## Amendment (spec 027): multi-arch, dual-image publish

Spec 027 extended this workflow to build and publish a second image
(`ghcr.io/intellectual-frontiers/workspaces-host-v3-press`, base + fish + the `press` persona) and
to build both images for both `linux/amd64` and `linux/arm64` rather than `amd64` only. The tag
contract FR-002 describes is unchanged in shape but now resolves correctly everywhere: **every
publish produces a `latest` tag and a `sha-<short-sha>` tag for both images, and each of those tags
is a multi-arch manifest list valid on both architectures** - `docker pull
.../workspaces-host-v3:sha-<short-sha>` (or `-press`) returns a native image whether the pulling
host is amd64 or arm64, with no `--platform` flag and no emulation. An IF repository that pins a
specific build still pins by `sha-<short-sha>` exactly as FR-002 already described; that pin now
simply works on either architecture instead of silently returning an amd64 image to run under
emulation on an Apple Silicon Mac. See specs/027-dual-image-multiarch-publish/spec.md for the
publish-pipeline mechanics (the build-matrix-plus-manifest-merge shape, and why GitHub's free
`ubuntu-24.04-arm` hosted runner makes this a native build, not cross-compilation).
