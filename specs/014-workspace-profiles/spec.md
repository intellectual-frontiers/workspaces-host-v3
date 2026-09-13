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

### Follow-up: combining and persisting personas (2026)

An engineer activated `fish` (`WORKSPACES_HOST_PROFILE=current-fish workspaces-host-update`),
ran `chsh` to make it their login shell, then later ran a plain `workspaces-host-update` (no
`WORKSPACES_HOST_PROFILE`) in response to the daily "you're behind origin/main" nudge.
`WORKSPACES_HOST_PROFILE` was never persisted anywhere - it only affects the one invocation that
sets it - so that plain run silently rebuilt the base `current` profile, which doesn't include
`programs.fish`, and `fish` disappeared from `~/.nix-profile/bin`. Their login shell in
`/etc/passwd` still named that now-empty path; `doctor`'s login-shell check only ever compared
that path as a string, so it kept reporting PASS even though the shell it named no longer
existed. Separately, and worse: `homeConfigurations.current-<persona>` (FR-001) was always base
plus exactly *one* persona module, so there was never a way to combine two personas (e.g.
`backend` and `fish` together) through the documented activation path at all, despite the docs
site's own "activate more than one and you get all of them together" claim - `home-manager
switch` fully replaces the active generation's module set on every call; it does not layer one
switch on top of a previous one.

Both problems shared one root cause (persona choice was a one-shot environment variable, never
declared state) and one fix: `~/.config/workspaces-host/personas`, a small file listing every
persona an engineer has activated, that `homeConfigurations.current` (not `current-<persona>`)
reads and folds into the same build alongside `./home` - so personas actually stack, and the
choice survives every future `workspaces-host-update` with no environment variable to remember.
`ws-persona activate`/`deactivate` (extending FR-011) edit that file; they still never run `nix
build`/`home-manager switch` themselves. `doctor`'s login-shell check (spec 004 FR-001) was
hardened at the same time to verify the shell binary the path names still actually exists, not
just that the string matches, closing the false-PASS hole directly.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Activate a specialized profile for my role (Priority: P2)

An engineer doing backend/data/mobile/agent-ops work wants the extra tools their day-to-day
needs, on top of everything the base profile already gives them, without those tools being
forced on every engineer who doesn't need them.

**Independent Test**: Build and activate `homeConfigurations.current-data`; confirm `uv`/`duckdb`
are present in addition to everything the base profile installs. Separately: `ws-persona
activate fish`, `ws-persona activate backend`, then build `homeConfigurations.current`; confirm
both persona's tools (`fish` and `mvn`/`redis-cli`/`docker-compose`) are present together in one
build.

**Acceptance Scenarios**:

1. **Given** the base profile alone, **When** an engineer instead activates
   `current-<persona>`, **Then** every base-profile tool is still present, plus that persona's
   extra packages.
2. **Given** an engineer who activates only the base profile (`current`), **When** they check
   their environment, **Then** no persona-specific package is present — personas are strictly
   additive and opt-in, never assumed.
3. **Given** an engineer has run `ws-persona activate` for two different personas, **When** they
   run `workspaces-host-update` (plain `current`, no `WORKSPACES_HOST_PROFILE`), **Then** both
   personas' tools are present together, and every base-profile tool is still present too.
4. **Given** an engineer activated a persona and ran `workspaces-host-update` at least once,
   **When** they run `workspaces-host-update` again later with no `WORKSPACES_HOST_PROFILE` set
   (e.g. from the daily update nudge), **Then** that persona's tools are still present - the
   choice persists without needing to be repeated.

### User Story 2 - Find out what personas exist, and what's already active (Priority: P2)

An engineer, especially one new to Nix, knows they want a specialized tool but doesn't want to
memorize six persona names or the flake-attribute syntax to activate one, and doesn't know
whether a persona is already active on their machine.

**Why this priority**: Activating a persona (a `nix build`/`home-manager switch` invocation
naming a specific flake attribute) is a small but real barrier for exactly the audience this
repository targets; discovering what's available shouldn't require reading `flake.nix`.

**Independent Test**: Run `ws-persona list` with no persona active; confirm every persona from
FR-003 through FR-009 (backend, data, mobile, agent-ops, compliance, networking) is named with a
one-line description and the exact command to activate it. Run `ws-persona activate backend`;
confirm `ws-persona current` reports it activated even before rebuilding. Rebuild; confirm it's
also reported detected. Run `ws-persona deactivate backend`; confirm it's no longer reported
activated.

**Acceptance Scenarios**:

1. **Given** any environment, **When** an engineer runs `ws-persona list`, **Then** every persona
   is named with what it adds and the exact one-line command to turn it on.
2. **Given** a persona whose marker tool (e.g. `mvn` for `backend`) is on `PATH`, **When** an
   engineer runs `ws-persona current`, **Then** that persona is reported as detected; the output
   also states this is a quick signal, not authoritative, and points to `doctor --all` for the
   full picture.
3. **Given** an engineer runs `ws-persona activate <persona>` for a valid persona name, **When**
   they run `ws-persona current` before rebuilding anything, **Then** that persona is reported as
   activated (recorded, pending a rebuild) even though it may not yet be detected on `PATH`.
4. **Given** an engineer runs `ws-persona activate` with a name that isn't a real persona,
   **When** the command runs, **Then** it fails with a clear error naming `ws-persona list` as
   the way to see valid names, and nothing is recorded.

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
- What happens when `~/.config/workspaces-host/personas` names a persona that doesn't exist (a
  typo, or one removed from a later version of this repository)? `flake.nix` drops it with a
  `builtins.trace` warning during evaluation rather than failing the whole `current` build - one
  bad line can't take down every persona an engineer has correctly activated.
- What happens to a login shell that was `chsh`'d to a persona's shell (e.g. `fish`) after that
  persona is later deactivated or falls out of the active generation some other way? The shell
  binary at that path disappears, but `/etc/passwd` still names it - `doctor` (spec 004 FR-001)
  checks that the binary still actually exists there, not just that the path string matches, and
  WARNs with the exact `ws-persona activate`/`workspaces-host-update` fix rather than reporting a
  false PASS.
- What happens when an engineer wants to try a persona once without committing to it? The
  existing `WORKSPACES_HOST_PROFILE=current-<persona> workspaces-host-update` path (FR-001) still
  works exactly as before: that one build is always exactly that one persona, ignores
  `~/.config/workspaces-host/personas` entirely, and never modifies it.

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
  `current-<persona>` MUST always build with exactly that one persona module, regardless of
  anything recorded by FR-013, so an engineer can try one persona in isolation without touching
  what they've activated.
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
  Activating more than one (FR-013) MUST combine every activated persona's packages together in
  the same `current` build, alongside the base profile, since FR-002 already guarantees no
  persona module can conflict with another.
- **FR-008**: The `compliance` persona MUST add the compliance/observability tooling from spec
  006: `cnquery`, `steampipe`, `openobserve`, `osquery` (Linux), and `surveilr` (`x86_64-linux`/
  `x86_64-darwin`).
- **FR-009**: The `networking` persona MUST add the zero-trust networking clients from spec 017:
  `tailscale` and `nebula`.
- **FR-010**: The environment health check (spec 004) MUST report every persona-specific tool as
  an informational WARN (not FAIL) when its persona isn't active, and MUST default to a terse
  report covering only the base profile's essentials (Nix, shell, git, credentials, GitHub/GitLab
  auth, `ws-repos`) unless run with `doctor --all` — a real FAIL is never hidden in either mode.
- **FR-011**: A `ws-persona` command MUST be installed on `PATH` by the base profile, with four
  subcommands: `list` (every persona, a one-line description of what it adds, and the exact
  command to activate it); `current` (which personas are activated per FR-013's state file,
  versus which look active right now based on one marker tool per persona being on `PATH`,
  explicitly labeled a heuristic rather than an authoritative check, and explicitly allowed to
  disagree until the next rebuild); `activate <persona>` (record a valid persona name in FR-013's
  state file, or fail with a clear error for an unrecognized name); and `deactivate <persona>`
  (remove one). `ws-persona` MUST NOT itself run `nix build`/`home-manager switch` — applying a
  change is always the caller's own subsequent `workspaces-host-update` (plain, no
  `WORKSPACES_HOST_PROFILE` needed once FR-013 exists), which this command only names, never
  runs. The one-off `WORKSPACES_HOST_PROFILE=current-<persona> workspaces-host-update` path (or
  the plain `nix build .../activate` two-step) MUST remain available and documented for trying a
  single persona without touching the activated list.
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
- **FR-013**: `homeConfigurations.current` MUST read `~/.config/workspaces-host/personas` (one
  persona name per line, `#` starting a whole-line or inline comment, blank lines ignored) if it
  exists, and include every named persona's module in the same build alongside `./home` -
  combining, not replacing, so activating `backend` and `fish` both means both are present
  together. An unrecognized name in that file MUST be dropped (a `builtins.trace` warning during
  evaluation, no hard failure) rather than breaking the whole build. This file MUST live outside
  the repository (same rationale as spec 013's `local.nix`) and MUST only be read by `current` -
  `nix flake check`'s pure evaluation MUST NOT see it, and `current-<persona>` (FR-001) MUST
  continue to ignore it entirely.

### Key Entities

- **Persona module**: one `home/profiles/<name>.nix` file — a small, focused package set on top
  of the shared base.
- **`ws-persona`**: a `list`/`current`/`activate`/`deactivate` command for personas. `activate`/
  `deactivate` edit the personas state file (FR-013); none of the four subcommands ever run `nix
  build`/`home-manager switch` themselves.
- **Personas state file** (`~/.config/workspaces-host/personas`): the declared, persistent record
  of which personas an engineer has activated - what FR-013's `current` build actually reads.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix flake check --all-systems` passes with all seven persona profiles included.
- **SC-002**: Every persona's activation package builds and includes both the base profile's
  full package set and that persona's own additions.
- **SC-003**: `doctor`'s default output covers only base-profile essentials, regardless of which
  personas exist or are documented — adding a new persona never grows the terse report.
- **SC-004**: An engineer who has never read `flake.nix` can name every available persona, what
  each adds, and the exact command to activate one, from `ws-persona list` alone.
- **SC-005**: `ws-persona activate` for two different personas, followed by one plain
  `workspaces-host-update` (no `WORKSPACES_HOST_PROFILE`), produces a single build containing
  both personas' tools together with the base profile - verified against a real scratch-`$HOME`
  activation, not just evaluation.
- **SC-006**: A persona activated once stays present across a second, later, plain
  `workspaces-host-update` run with no `WORKSPACES_HOST_PROFILE` set - the choice is never lost
  to an ordinary update.

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
