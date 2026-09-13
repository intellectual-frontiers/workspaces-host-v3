# Feature Specification: Workspace Profiles (Personas)

**Feature Branch**: `014-workspace-profiles`

**Created**: 2026-09-13

**Status**: Implemented

**Input**: User description: "Per-persona home-manager profiles (backend, data, mobile,
agent-ops) layering specialized package sets on top of the shared base profile"

## Background

workspaces-host-v2 shipped four persona profiles (`backend`, `data`, `mobile`, `agent-ops`),
each a small, focused package set layered on the shared base. When v3 was rebuilt fresh, the
persona *mechanism* was deliberately dropped as an unnecessary layer of complexity for a from-
scratch rewrite (Constitution Principle V) — but that also silently orphaned the packages each
persona carried (`uv`/`duckdb` trace back to workspaces-host-v1's own tool set; the rest were
v2's own additions), with no spec anywhere covering them. This spec restores the mechanism and
those packages, now that they're wanted.

### Follow-up: newbie-simplification audit (2026)

A later audit of this repository against its own stated target audience — including engineers
new to Linux/the command line, not necessarily Nix-literate — found that most specs after 005
had, without ever asking Principle V's "should this be opt-in" question, landed straight in the
base profile: compliance tooling (spec 006), the Java/Postgres toolchain (spec 007), bulk git
tooling (spec 011), and zero-trust networking clients (spec 017) together made up the single
largest source of `doctor` noise and installed-package weight for an engineer who would never use
any of them. This spec's own persona mechanism was the natural fix: two new personas
(`compliance`, `networking`) were added, `backend` grew to include the Java/Postgres toolchain,
and `agent-ops` grew to include the specialized half of spec 011's git tooling and spec 015's
`gopass`/`deno`, plus `llm` (spec 008). See each of those specs' own "Background" sections for
the per-feature rationale; this spec's own FRs below reflect the result.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Activate a specialized profile for my role (Priority: P2)

An engineer doing backend/data/mobile/agent-ops work wants the extra tools their day-to-day
needs, on top of everything the base profile already gives them, without those tools being
forced on every engineer who doesn't need them.

**Independent Test**: Build and activate `homeConfigurations.current-data`; confirm `uv`/`duckdb`
are present in addition to everything the base profile installs.

**Acceptance Scenarios**:

1. **Given** the base profile alone, **When** an engineer instead activates
   `current-<persona>`, **Then** every base-profile tool is still present, plus that persona's
   extra packages.
2. **Given** an engineer who activates only the base profile (`current`), **When** they check
   their environment, **Then** no persona-specific package is present — personas are strictly
   additive and opt-in, never assumed.

### Edge Cases

- What happens when a persona needs a package only available on some platforms (e.g. mobile's
  `android-tools`)? The persona module itself may be platform-restricted the same way core specs
  handle this (spec 005/006's Linux/Darwin conditionals); this spec's four personas all happen to
  use packages available on Linux and Darwin alike.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The flake MUST expose one `homeConfigurations.<persona>` (fixed test identity,
  pinned to `x86_64-linux`, for `nix flake check`) and one `homeConfigurations.current-<persona>`
  (impure, real identity) per persona module, in addition to `default`/`current`.
- **FR-002**: Every persona module MUST import the shared `./home` module set and add only its
  own extra `home.packages` — it MUST NOT redefine or override anything the base profile already
  configures.
- **FR-003**: The `backend` persona MUST add `postgresql` (client), `redis`, `docker-compose`,
  `httpie`, and (per spec 007's own newbie-simplification follow-up) the Java/Postgres toolchain:
  a pinned JDK/Maven and the `pgpass` CLI, by importing `home/java.nix` and `home/postgres.nix`.
- **FR-004**: The `data` persona MUST add `python3`, `uv`, and `duckdb`.
- **FR-005**: The `mobile` persona MUST add `android-tools` (`adb`/`fastboot`) and `watchman`.
- **FR-006**: The `agent-ops` persona MUST add `act` (`gh` is already in the shared base via
  spec 008's `home/ai-harness.nix`, so it is not duplicated here), plus (per specs 008/011/015's
  own newbie-simplification follow-ups) `git-extras`, `semtag`, `git-standup`, `gopass`, `deno`,
  and `llm`.
- **FR-007**: Activating no persona (`default`/`current`) MUST be completely unaffected by this
  feature's existence — personas are additive, opt-in profiles, never a change to the base.
- **FR-008**: The `compliance` persona MUST add the compliance/observability tooling from spec
  006: `cnquery`, `steampipe`, `openobserve`, `osquery` (Linux), and `surveilr` (`x86_64-linux`/
  `x86_64-darwin`).
- **FR-009**: The `networking` persona MUST add the zero-trust networking clients from spec 017:
  `tailscale` and `nebula`.
- **FR-010**: The environment health check (spec 004) MUST report every persona-specific tool as
  an informational WARN (not FAIL) when its persona isn't active, and MUST default to a terse
  report covering only the base profile's essentials (Nix, shell, git, credentials, GitHub/GitLab
  auth, `ws-repos`) unless run with `doctor --all` — a real FAIL is never hidden in either mode.

### Key Entities

- **Persona module**: one `home/profiles/<name>.nix` file — a small, focused package set on top
  of the shared base.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix flake check --all-systems` passes with all six persona profiles included.
- **SC-002**: Every persona's activation package builds and includes both the base profile's
  full package set and that persona's own additions.
- **SC-003**: `doctor`'s default output covers only base-profile essentials, regardless of which
  personas exist or are documented — adding a new persona never grows the terse report.

## Assumptions

- Full platform-specific toolchains (a full Android SDK, Xcode) remain out of scope — the
  `mobile` persona covers what's cleanly packageable in Nix, the same boundary v2 drew.
- A persona module may itself import an existing shared module (e.g. `backend` importing
  `home/java.nix`/`home/postgres.nix`) rather than only adding plain `home.packages` — FR-002's
  "own extra `home.packages`" restriction is about not touching *other* modules' configuration,
  not about which file a persona's own additions live in.
