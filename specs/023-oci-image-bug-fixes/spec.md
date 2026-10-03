# Feature Specification: OCI Image Bug Fixes

**Feature Branch**: `023-oci-image-bug-fixes`

**Created**: 2026-10-03

**Status**: Implemented

**Input**: User description: "Every Intellectual Frontiers repo is moving to 'no setup step after
clone, tooling runs in workspaces-host-v3' - testing the published image against a real IF repo
(`.github`) surfaced three real bugs that block that promise: no `/usr/bin/env`, home-manager
session variables never load, and `node` can't `require(\"playwright\")`."

## Background

Spec 005/020's OCI image copies specific dotfiles and adds `cfg.home.packages` to
`dockerTools.buildLayeredImage`'s `contents`, rather than running full home-manager activation
(there is no `~/.nix-profile` symlink farm in the image at all). Three consequences of that
shortcut, invisible until a real downstream repo's scripts actually ran inside the image:

1. **No `/usr/bin/env`.** `dockerTools` images start from nothing - no FHS paths exist unless a
   package provides them. Any script with a `#!/usr/bin/env bash`/`python3`/`node` shebang (the
   overwhelming majority of real-world scripts, including `.github`'s own `tools/run_assurance.sh`)
   fails outright with "cannot execute: required file not found."
2. **Session variables never load.** `oci/default.nix` copies home-manager's generated `.profile`
   verbatim. That file's one line sources
   `"<home.homeDirectory>/.nix-profile/etc/profile.d/hm-session-vars.sh"` - a path home-manager
   bakes in literally at eval time, assuming its own `switch`-created profile symlink exists. The
   image's `homeConfig` (flake.nix's `homeConfigurationsForImage`) was evaluated with
   `home.homeDirectory = "/home/workspace"` (the same fixed test identity every other
   `homeConfigurationsFor` build uses) while the container's actual `$HOME` is `/root` - two
   mismatches stacked on each other (wrong path, and nothing at either path), so every
   `home.sessionVariables` entry (`PLAYWRIGHT_BROWSERS_PATH`, `PUPPETEER_EXECUTABLE_PATH`, ...) is
   silently unset in every login shell. Fish is unaffected: home-manager's fish integration embeds
   a direct `/nix/store/...` reference to the same script instead of the nix-profile convention,
   which Nix's own closure-scanning already carries into the image's `extraCommands` output - only
   bash's `.profile` needed a code change, but it is bash this profile still defaults to.
3. **`node` can't `require("playwright")`.** `playwright-test` (home/ai-harness.nix) provides the
   CLI; nixpkgs doesn't put its own `lib/node_modules` on `NODE_PATH` for a plain `node` process to
   resolve `require("playwright")` against. True on every flavor this flake produces, not only the
   image - confirmed by setting `PLAYWRIGHT_MODULE`/`NODE_PATH` by hand and getting `.github`'s
   design-system harness (11/11 tests) to pass.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A real downstream repo's scripts just run (Priority: P1)

An engineer or AI agent clones an Intellectual Frontiers repository inside this flake's published
image (or any flavor built from the same closure) and runs that repo's own tooling with no setup
step first.

**Why this priority**: This is the literal promise every IF repo is adopting - "no `make install`,
ever, in any flavor." A shebang that can't execute or an env var that's silently empty breaks it
for scripts nobody in this repository wrote or controls.

**Independent Test**: `docker run --rm -v "$PWD":/work -w /work <image> bash -lc 'tools/run_assurance.sh'`
against a real `.github` checkout exits 0, with no `/usr/bin/env` or `hm-session-vars.sh` error on
the way.

**Acceptance Scenarios**:

1. **Given** the published image, **When** a login shell starts, **Then** no
   `hm-session-vars.sh: No such file or directory` error prints, and every `home.sessionVariables`
   entry (checked via `PLAYWRIGHT_BROWSERS_PATH`) is set and valid.
2. **Given** the published image, **When** a script with a `#!/usr/bin/env <interpreter>` shebang
   is executed directly, **Then** it runs instead of failing with "required file not found."
3. **Given** the published image, **When** plain `node -e 'require("playwright")'` runs, **Then**
   it succeeds.

### Edge Cases

- A real host install (not the image) was never affected by #1/#2 - `install.sh` runs genuine
  home-manager activation, which creates the real `~/.nix-profile` symlink farm `/usr/bin/env`'s
  absence and the nix-profile path both assume. #3 (NODE_PATH) is a real gap everywhere, fixed at
  the base-profile level so every flavor gets it, not just the image.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Both `oci/default.nix` and `oci/sandboxed.nix` MUST include `dockerTools.usrBinEnv`
  (or equivalent) in `contents`, so `/usr/bin/env` exists in the built image.
- **FR-002**: The image's home configuration (flake.nix's `homeConfigurationsForImage`, and the new
  press-image equivalent from spec 027) MUST be evaluated with `home.username`/`home.homeDirectory`
  matching the container's actual runtime identity (`root`/`/root`, the image's own `Env`/
  `WorkingDir`), not the fixed `workspace`/`/home/workspace` test identity every other
  `homeConfigurationsFor` build uses.
- **FR-003**: `oci/default.nix`'s `extraCommands` MUST materialize `hm-session-vars.sh` at the
  exact path the copied `.profile` sources (`root/.nix-profile/etc/profile.d/hm-session-vars.sh`
  once FR-002 lands), as a real file (consistent with the existing `/etc/passwd`/`/etc/group`
  fix's "copy, don't symlink" approach for container tooling that won't follow a store-path
  symlink).
- **FR-004**: The base profile (home/ai-harness.nix or home/tools.nix) MUST add
  `${pkgs.playwright-test}/lib/node_modules` to `NODE_PATH` via `home.sessionVariables`, so a plain
  `node` process run by any script (not just the `playwright` CLI itself) can `require("playwright")`.
- **FR-005**: `doctor` MUST check `/usr/bin/env` exists and is executable, and (when `node` is on
  PATH) that `node -e 'require("playwright")'` succeeds - two new checks; the existing
  `PLAYWRIGHT_BROWSERS_PATH` check already confirms both non-empty and that the directory exists.

### Key Entities

- **`oci/default.nix` / `oci/sandboxed.nix`**: the two image definitions FR-001/002/003 touch.
- **`home/ai-harness.nix`**: where `NODE_PATH` (FR-004) and `PLAYWRIGHT_BROWSERS_PATH` already
  live.
- **`pkgs/doctor/doctor`**: FR-005's new checks.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Inside a freshly built/pulled image, `bash -lc 'doctor'` reports no FAIL for
  `/usr/bin/env`, `PLAYWRIGHT_BROWSERS_PATH`, or `node -e require(playwright)`, and prints no raw
  shell error about a missing `hm-session-vars.sh`.
- **SC-002**: A real downstream repo's own `#!/usr/bin/env`-shebanged script, mounted into the
  image with no setup step, executes successfully.

## Assumptions

- Fixing bash's `.profile`/nix-profile mismatch (FR-002/003) rather than papering over just the one
  broken path is preferred: it also fixes every other `${config.home.homeDirectory}`-relative value
  baked into the image's copied config (e.g. `WORKSPACES_HOST_REPO`) to actually match where the
  container's `$HOME` points, instead of leaving a second, latent mismatch behind.
