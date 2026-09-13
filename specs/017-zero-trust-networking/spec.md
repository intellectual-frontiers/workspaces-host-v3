# Feature Specification: Zero-Trust Networking Clients

**Feature Branch**: `017-zero-trust-networking`

**Created**: 2026-09-13

**Status**: Implemented

**Input**: User description: "Tailscale and Nebula mesh VPN clients for securely tunneling local
services, fulfilling v1's unfinished roadmap item"

## Background

workspaces-host-v1's README carried an unchecked roadmap item: "Integrate Zero Trust client
infrastructure starting with Tailscale... and then add Nebula... opinionated options," with a
fallback note pointing at other tunneling tools if neither fit. v1 never built this. Nix can
provision the *clients* declaratively the same as every other tool here; joining an actual mesh
(a Tailscale account and its login flow, or a Nebula CA certificate issued by a network admin)
is unavoidably a human, out-of-band action — the same category as a git identity or an API key
(Constitution Principle III's "provisioning the key is a deliberate, separate, human action"
applies equally to network trust material). This spec provisions the tooling and documents that
boundary; it does not stand up any server-side control plane (a self-hosted Headscale instance,
a Nebula lighthouse) — that is infrastructure operators choose to run, not part of one
engineer's sandbox.

A later newbie-simplification audit (see spec 014's own follow-up) moved both clients behind the
`networking` persona (spec 014) instead of the base profile — most engineers never touch a VPN
client on day one, and until they do, this is one fewer thing for `doctor` to mention.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Join my team's tailnet without installing anything myself (Priority: P3)

An engineer wants to securely reach a teammate's local service (or expose their own) over
Tailscale, without a separate install step.

**Independent Test**: On an activated profile, run `tailscale version`; confirm it resolves with
no separate install step. Joining a real tailnet is out of scope for an automated test — it
requires an interactive login against a real account.

**Acceptance Scenarios**:

1. **Given** an activated base profile, **When** the engineer runs `sudo tailscale up`, **Then**
   they're taken through Tailscale's own interactive login flow — the client is present, nothing
   about joining is automated or assumed.

---

### User Story 2 - Join a Nebula mesh with an issued certificate (Priority: P3)

An engineer who's been issued a Nebula certificate by their network's admin wants to join that
mesh.

**Independent Test**: On an activated profile, run `nebula -version`; confirm it resolves with no
separate install step.

### Edge Cases

- What happens on a platform/container without the capability to create a TUN device (common in
  restricted sandboxes)? The client binaries are still installed and usable for offline
  inspection (`tailscale version`, cert tooling); actually bringing up the interface will fail
  with that runtime's own clear error — this spec does not attempt to work around a sandbox's
  networking restrictions.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `networking` persona (spec 014) MUST install the `tailscale` client.
- **FR-002**: The `networking` persona MUST install the `nebula` client.
- **FR-003**: This feature MUST NOT provision, configure, or auto-start any always-on background
  service (no `systemd`/`launchd` unit) — joining and connecting are always an explicit,
  engineer-initiated action, consistent with a workstation sandbox rather than a managed fleet.
- **FR-004**: The environment health check (spec 004) MUST report both clients as an informational
  WARN (not FAIL) when the `networking` persona isn't active, and PASS when present — this is
  optional infrastructure, the same tier as `docker` in spec 005.
- **FR-005**: README MUST document the human-in-the-loop steps this feature deliberately does not
  automate: Tailscale's interactive `tailscale up` login, and that a Nebula certificate must be
  issued by the mesh's own CA/admin before `nebula` can join anything.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Both clients are present immediately after activation with no manual install step.
- **SC-002**: Neither client attempts any network action on its own at activation time — both
  are inert until the engineer explicitly runs them.

## Assumptions

- Running an actual Headscale control-plane server, or a Nebula lighthouse, is infrastructure
  operators run separately — entirely out of scope for a per-engineer sandbox flake.
