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

### Follow-up: ws-persona and the fish persona (2026)

Engineers new to Nix found activating a persona itself a real barrier: the `nix build
".#homeConfigurations.current-<persona>.activationPackage" --impure` incantation assumes exactly
the flake-attribute literacy this repository otherwise tries not to require. `ws-persona`
(FR-011) closes that gap with a discovery command, not a new activation mechanism - activation was
already a single line via `workspaces-host-update`'s `WORKSPACES_HOST_PROFILE` variable, just
undocumented and unsurfaced.

Separately, an engineer reported bash's `blesh`-based line editor feeling slow to type in.
Root cause: `blesh`'s default configuration auto-triggers full completion (not just its
lightweight, fish-like grey suggestion) on almost every keystroke. A `bleopt` setting fixes that
for anyone who wants to keep bash. For anyone who wants the real thing instead, a `fish` persona
(FR-012) offers fish's own native line editor, written in Rust as of fish 4.x - additive, like
every other persona, and never a change to anyone else's shell.

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

### User Story 2 - Find out what personas exist, and what's already active (Priority: P2)

An engineer, especially one new to Nix, knows they want a specialized tool but doesn't want to
memorize six persona names or the flake-attribute syntax to activate one, and doesn't know
whether a persona is already active on their machine.

**Why this priority**: Activating a persona (a `nix build`/`home-manager switch` invocation
naming a specific flake attribute) is a small but real barrier for exactly the audience this
repository targets; discovering what's available shouldn't require reading `flake.nix`.

**Independent Test**: Run `ws-persona list` with no persona active; confirm every persona from
FR-003 through FR-009 (backend, data, mobile, agent-ops, compliance, networking) is named with a
one-line description and the exact command to activate it. Activate `backend`; run `ws-persona
current`; confirm it's reported active.

**Acceptance Scenarios**:

1. **Given** any environment, **When** an engineer runs `ws-persona list`, **Then** every persona
   is named with what it adds and the exact one-line command to turn it on.
2. **Given** a persona whose marker tool (e.g. `mvn` for `backend`) is on `PATH`, **When** an
   engineer runs `ws-persona current`, **Then** that persona is reported as active; the output
   also states this is a quick signal, not authoritative, and points to `doctor --all` for the
   full picture.

### Edge Cases

- What happens when a persona needs a package only available on some platforms (e.g. mobile's
  `android-tools`)? The persona module itself may be platform-restricted the same way core specs
  handle this (spec 005/006's Linux/Darwin conditionals); this spec's four personas all happen to
  use packages available on Linux and Darwin alike.
- What happens when `ws-persona current`'s marker-tool check gives a false signal (the marker
  tool happens to be installed some other way, or a persona's own package failed to build)? It's
  documented as a heuristic, not a guarantee, in the command's own output - `doctor --all` remains
  the authoritative check, since it verifies each persona's own set of tools directly.
- What happens when someone activates the `fish` persona expecting it to become their shell? It
  doesn't, and can't: home-manager has no way to write `/etc/passwd`. Both `ws-persona list` and
  the docs site name the separate, manual `chsh -s $(which fish)` step explicitly, rather than
  leaving "why didn't my shell change" to be discovered the hard way.

---

### User Story 3 - A faster-feeling shell without giving up bash for everyone (Priority: P3)

An engineer who finds `blesh`'s default keystroke-time completion noticeably slow wants either a
quick fix that keeps bash, or a real native alternative, without that choice being forced on
every other engineer using this repository.

**Why this priority**: This is a real, reported friction point, but a workaround (a `bleopt`
setting) already exists for anyone who wants to keep bash; a whole second shell is the option for
someone who wants more than a workaround.

**Independent Test**: Activate the `fish` persona; confirm `fish` is on `PATH` with the same
aliases bash gets, and that no other engineer's `default`/`current` activation changed at all.

**Acceptance Scenarios**:

1. **Given** the base profile alone, **When** an engineer activates the `fish` persona, **Then**
   `fish` becomes available with matching aliases and the same prompt/`zoxide`/`fzf` integration
   bash already had, and their login shell is unchanged until they run `chsh` themselves.
2. **Given** any other persona or the base profile alone, **When** `fish` exists as a persona,
   **Then** nothing about their own activation changes.

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
- **FR-011**: A `ws-persona` command MUST be installed on `PATH` by the base profile, with two
  subcommands: `list` (every persona, a one-line description of what it adds, and the exact
  command to activate it) and `current` (which persona(s) look active, based on one marker tool
  per persona being on `PATH`, explicitly labeled a heuristic rather than an authoritative
  check). `ws-persona` MUST NOT itself run `nix build`/`home-manager switch` — activation stays a
  single documented command (`WORKSPACES_HOST_PROFILE=current-<persona> workspaces-host-update`,
  or the plain `nix build .../activate` two-step) that this command only prints, never runs.
- **FR-012**: The `fish` persona MUST enable fish as an additional shell (`programs.fish`) with
  the same aliases home/shell.nix gives bash (`ll`, `ls`, `cat`, `g`, `deno-run`, `deno-test`,
  `cdp`), and MUST preserve the same daily-update-nudge and SSH-agent-auto-start behavior bash
  gets, translated to fish's own syntax rather than dropped. It MUST NOT change the caller's login
  shell (home-manager cannot write `/etc/passwd`, and personas stay additive regardless); making
  it the actual login shell MUST be documented as a separate, manual, two-command step - adding
  the Nix-installed path to `/etc/shells` (not there by default, and `chsh` refuses any shell that
  isn't - verified directly against a real non-root user, not assumed), then `chsh` itself - never
  implied as the one command it isn't. The environment health check (spec 004 FR-001) MUST treat
  fish as a correct login shell choice, not just bash, once this persona exists.

### Key Entities

- **Persona module**: one `home/profiles/<name>.nix` file — a small, focused package set on top
  of the shared base.
- **`ws-persona`**: a discovery-only command (`list`/`current`) for personas, distinct from
  activation itself.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix flake check --all-systems` passes with all seven persona profiles included.
- **SC-002**: Every persona's activation package builds and includes both the base profile's
  full package set and that persona's own additions.
- **SC-003**: `doctor`'s default output covers only base-profile essentials, regardless of which
  personas exist or are documented — adding a new persona never grows the terse report.
- **SC-004**: An engineer who has never read `flake.nix` can name every available persona, what
  each adds, and the exact command to activate one, from `ws-persona list` alone.

## Assumptions

- Full platform-specific toolchains (a full Android SDK, Xcode) remain out of scope — the
  `mobile` persona covers what's cleanly packageable in Nix, the same boundary v2 drew.
- A persona module may itself import an existing shared module (e.g. `backend` importing
  `home/java.nix`/`home/postgres.nix`) rather than only adding plain `home.packages` — FR-002's
  "own extra `home.packages`" restriction is about not touching *other* modules' configuration,
  not about which file a persona's own additions live in. The `fish` persona follows the same
  rule by enabling a whole new `programs.fish` subsystem rather than plain packages, the same
  precedent `backend` already set.
- fish 4.x (the Rust rewrite) requires nixpkgs `nixos-25.05` or newer; this repository's nixpkgs
  pin was bumped from `nixos-24.11` specifically for this persona (flake.nix).
