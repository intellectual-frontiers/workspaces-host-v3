# Feature Specification: Container & Cloud-Harness Parity

**Feature Branch**: `005-container-parity`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "OCI container image built from the same flake outputs as the host
environment, for CI and cloud AI-agent sessions"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Same environment, as a container (Priority: P1)

A CI pipeline or a cloud AI-agent session needs the exact same shell, tools, and dotfiles a human
engineer gets on a host machine, packaged as a container image with no separate maintenance
burden.

**Why this priority**: Constitution Principle IV makes this a first-class target, not an
afterthought — a container image that drifts from the host closure defeats the reproducibility
promise everywhere it matters most (automated, unattended contexts).

**Independent Test**: Build the image derivation with a plain `nix build`, run it, and confirm the
same tool versions and generated dotfiles present on the host profile are present in the
container.

**Acceptance Scenarios**:

1. **Given** the flake's host home-manager configuration, **When** the OCI image derivation is
   built, **Then** its package set and generated dotfiles are derived from that same
   configuration, not a separately maintained list.
2. **Given** the built image, **When** it is run as a plain container, **Then** the shell, git,
   and every ported tool resolve on `PATH` with no additional setup step.

---

### User Story 2 - A network-restricted variant for untrusted agent workloads (Priority: P2)

An operator running an AI agent in a container wants network access restricted to an explicit
allowlist of domains, with the agent process itself unable to modify that restriction.

**Why this priority**: A coding agent with unrestricted outbound network access inside its own
sandbox is a materially larger blast radius than one confined to the domains it actually needs.

**Independent Test**: Run the sandboxed image variant with a small allowlist; confirm a request to
an allowlisted domain succeeds and a request to a non-allowlisted domain fails, from inside the
container.

**Acceptance Scenarios**:

1. **Given** the sandboxed image variant with a configured domain allowlist, **When** the
   container starts, **Then** outbound traffic to allowlisted domains succeeds and traffic to
   everything else is dropped, verified by the entrypoint's own self-check before handing off to
   the workload.
2. **Given** the sandboxed image running as its unprivileged workload user, **When** that user
   attempts to alter the network restriction, **Then** the attempt fails — only the entrypoint's
   own root-then-drop-privileges setup step may configure it.

### Edge Cases

- What happens when building the image derivation on a machine with no container engine
  installed? Building must still succeed; only *running* the resulting image needs a container
  runtime.
- What happens when the container runtime does not grant the capability needed to configure
  network restrictions (e.g. a restricted CI runner)? An explicit, documented opt-out must exist
  for that case — never a silent fallback to "restriction failed, continue anyway."
- What happens when a TLS request or a UID/GID lookup is attempted inside the plain (non-sandboxed)
  image? It must succeed out of the box — the image needs CA certificates and minimal NSS files
  bundled, not left to the caller to configure.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The flake MUST expose an OCI image, buildable via a plain `nix build` with no
  external Dockerfile.
- **FR-002**: The image's package set and generated dotfiles MUST be derived from the same
  home-manager configuration evaluation the host profile (spec 001) uses.
- **FR-003**: The image MUST be runnable as a plain container with no additional setup, resolving
  the shell, git, and every ported tool on `PATH`.
- **FR-004**: The image MUST include CA certificates and minimal NSS files so TLS requests and
  UID/GID lookups work inside the container without extra configuration.
- **FR-005**: The flake MUST also expose a network-restricted image variant that: resolves an
  explicit domain allowlist to IP addresses and firewalls all other outbound traffic; self-verifies
  the restriction immediately after applying it and fails loudly if verification fails; runs its
  workload as a non-root user with no ability to alter the restriction; and supports one explicit,
  documented opt-out for container runtimes that cannot grant the needed network-configuration
  capability.
- **FR-006**: Building either image derivation MUST NOT require a running container engine; only
  running the resulting image does.

### Key Entities

- **OCI image**: the plain container image sharing the host profile's closure.
- **Sandboxed OCI image variant**: the network-restricted image built on top of the plain image's
  closure, with a non-root workload user.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The plain container image, run with no setup, has every tool the host profile
  installs available on `PATH`.
- **SC-002**: The sandboxed image variant blocks 100% of outbound requests to non-allowlisted
  domains in verification, while allowlisted domains succeed.
- **SC-003**: CI builds and runs `doctor` against both image variants on every push and pull
  request, catching drift between the host profile and the container images before merge.

## Assumptions

- The plain image's default workload command is the same interactive shell the host profile
  configures; a from-scratch, no-shell "distroless" variant is out of scope for this spec.
- The sandboxed variant's default domain allowlist covers the package registries and git hosts
  this repository itself needs; per-project allowlist customization is a documented runtime
  override, not a rebuild.
