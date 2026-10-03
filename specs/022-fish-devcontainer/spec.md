# Feature Specification: Fish Devcontainer

**Feature Branch**: `022-fish-devcontainer`

**Created**: 2026-10-03

**Status**: Implemented

**Input**: User description: "A second devcontainer that opens straight into the fish persona,
without publishing a second image"

## Background

The obvious design for "a devcontainer that opens into fish" is a second, fish-specific image. The
simpler one, adopted here instead: the devcontainer CLI/VS Code never actually launch a container's
own baked `Cmd`/`Entrypoint` as the interactive terminal - they override the entrypoint to keep the
container alive and open each terminal through their own exec mechanism. Which shell greets you is
therefore a `devcontainer.json`-level choice (`remoteEnv.SHELL`, `customizations.vscode.settings`),
not an image-level one. Combined with personas being strictly additive (the `fish` persona adds
`fish` and its own config; it changes nothing about `bash`), one image already containing both
shells serves both devcontainer configs - this reuses the one image spec 020/021 already publish,
rather than doubling the CI build/publish surface spec 020's own Background already reasoned about
avoiding.

The published image's underlying home config changed accordingly: `packages.<system>.oci-image`
(flake.nix) now builds from base + the `fish` persona (`homeConfigurationsForImage`, a new
all-systems counterpart to the existing x86_64-linux-only `personaConfigurations.fish`, needed
because the image itself is built `forAllSystems`) instead of bare base. The image's own `Cmd`
still launches bash - nothing changes for anyone who doesn't open the `-fish` devcontainer config -
fish is simply also present and configured, the same relationship the persona has on a real host
install. `oci-image-sandboxed` (a different use case entirely, spec 005) was deliberately left
building from bare base - this only touches the one image spec 020 publishes.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open straight into fish (Priority: P3)

An engineer who prefers fish opens this repository's `-fish` devcontainer config (or copies it
into another project) and lands in a fish prompt immediately, with no `ws-persona activate`/rebuild
step - the same tools and dotfiles as the default devcontainer, just a different default shell.

**Independent Test**: `devcontainer up --workspace-folder . --config
.devcontainer/fish/devcontainer.json`, then open a terminal and confirm it's fish, not bash.

**Acceptance Scenarios**:

1. **Given** the `-fish` devcontainer config, **When** the container starts, **Then** it pulls the
   exact same image the default devcontainer config does - no second image to build or publish.
2. **Given** that same container, **When** a terminal opens (VS Code's integrated terminal, or any
   tool reading `$SHELL`), **Then** it's fish, with the same aliases (`ll`, `g`, ...) and `cdp`
   function the fish persona gives a real host install.
3. **Given** the default (non-`-fish`) devcontainer config against that same image, **When** a
   terminal opens, **Then** it's still bash, unchanged from before this feature.

### Edge Cases

- What happens to a real host install (not a container)? Nothing - `ws-persona activate fish` is
  still the one and only way to turn fish on there, exactly as spec 014 already specifies. This
  feature only changes what ships inside the published image and which shell a devcontainer config
  defaults to; it does not change the persona-activation model itself.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `packages.<system>.oci-image` MUST be built from base + the `fish` persona on every
  system the flake targets, not bare base - a new `homeConfigurationsForImage` (flake.nix), since
  the existing `personaConfigurations.fish` is pinned to `x86_64-linux` only.
- **FR-002**: The image's own `Cmd` MUST remain a bash login shell - this feature MUST NOT change
  the default experience of `docker run`/the default devcontainer config.
- **FR-003**: The repository MUST provide `.devcontainer/fish/devcontainer.json`, referencing the
  same published image as the default config, setting `remoteEnv.SHELL` to the fish binary's path
  and `customizations.vscode.settings["terminal.integrated.defaultProfile.linux"]` to `"fish"`.
- **FR-004**: `oci-image-sandboxed` MUST continue building from bare base (unchanged) - this
  feature is scoped to the one image spec 020 publishes.

### Key Entities

- **`homeConfigurationsForImage`**: base + `fish` persona, evaluated for every system
  `oci-image` targets - distinct from the existing `personaConfigurations.fish` (interactive
  persona testing, one system only).
- **`.devcontainer/fish/devcontainer.json`**: the second devcontainer config - same image as the
  default, different default shell.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Exactly one image is published (spec 020 unchanged) - two devcontainer configs share
  it.
- **SC-002**: `devcontainer up` against the `-fish` config succeeds and a shell opened inside it is
  fish; against the default config, it's still bash.

## Assumptions

- Devcontainer-aware tooling (VS Code, Codespaces, the standalone CLI) resolves the shell a
  terminal opens from `$SHELL`/its own settings, not from the image's `Cmd`/`Entrypoint` - verified
  directly against the real `devcontainer` CLI (`@devcontainers/cli`) rather than assumed from the
  spec alone.
