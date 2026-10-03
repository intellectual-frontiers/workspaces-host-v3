# Feature Specification: Rust Toolchain Persona and Image

**Feature Branch**: `029-rust-toolchain-persona-image`

**Created**: 2026-10-03

**Status**: Implemented

**Input**: User description: "A `rust` persona: a stable Rust toolchain (>=1.85, for edition 2024)
via nixpkgs if new enough, else a pinned overlay/fenix input - never rustup; plus the native build
toolchain (cc/linker, cmake, pkg-config, perl, gnumake) its heaviest crate graphs (aws-lc-sys, ring,
via reqwest+rustls) actually need; plus a writable CARGO_HOME under $HOME. Published as a third OCI
image, same tag scheme as the other two, so `www.intellectualfrontiers.com` (Rust + Axum + Maud,
edition 2024) has no Rust toolchain and no C toolchain at all today."

## Background

`intellectual-frontiers/www.intellectualfrontiers.com` is a Rust + Axum + Maud site (`rust-version
= "1.85"`, edition 2024) whose entire command surface is `cargo task <name>`. Neither published
image (spec 020's base, spec 025/027's press) carries any Rust or C toolchain - confirmed directly:
`command -v cargo rustc cc gcc ld pkg-config cmake` on the base image returns nothing. No persona
fills this gap either. Its own dependency tree (`reqwest` built against `rustls`) pulls in
`aws-lc-sys` and `ring`, both of which compile C and assembly at `cargo build` time rather than
merely linking a prebuilt library - the actual reason a bare Rust toolchain alone isn't enough; a
C compiler, a linker, and CMake have to be present too.

This flake's pinned nixpkgs revision (`nixos-25.05`) already ships `rustc`/`cargo`/`clippy`/
`rustfmt` at 1.86.0 - checked directly (`nix eval`), not assumed - which clears the >=1.85 floor
edition 2024 needs, so this persona uses nixpkgs' own packages rather than a second flake input
(rust-overlay/fenix) or an imperative installer (rustup, which manages toolchains entirely outside
Nix - Constitution Principle I forbids exactly this). `rust-analyzer` comes from the same pinned
nixpkgs revision, so it's never out of sync with the rustc it analyzes, and nixpkgs'
`rustPlatform.rustLibSrc` provides the standard library source rust-analyzer needs
(`RUST_SRC_PATH`) without a separate `rustup component add rust-src` step that doesn't exist in
this setup anyway.

The native build toolchain was verified the same way `press` verified its own tools: not assumed
from a package list, but by actually building `reqwest` (rustls-only, no default features) end to
end against this persona's exact package set, the hardest native dependency an Intellectual
Frontiers repo's own `Cargo.toml` currently pulls in. `stdenv.cc` (this platform's own default
compiler wrapper - GCC on Linux, Clang on Darwin) already bundles its own linker (`ld`/`ar`/`as`/
etc., from GNU binutils on Linux) in one package, so nothing beyond `stdenv.cc` plus `cmake`/
`pkg-config`/`perl` was needed; `gnumake` is already unconditional in the base profile
(`home/tools.nix`), so it isn't duplicated here. Using `stdenv.cc` rather than a hardcoded `gcc`
also avoids forcing a from-source GCC build on Darwin, where nixpkgs doesn't carry cached GCC
binaries the way it does for the platform's own default Clang-based `stdenv.cc`.

A writable `CARGO_HOME` under `$HOME` (not the Nix store, which is read-only at runtime) is what
lets `cargo add`/`cargo build` write the registry index and git checkout caches every run produces
- the same "point a tool's real writable state at $HOME, not the store" pattern `WORKSPACES_HOST_
REPO` (home/shell.nix) and `JAVA_HOME`/`pgpass` (home/java.nix, home/postgres.nix) already use.

Like `press`, this toolchain is real weight (a full Rust + C/CMake toolchain) that only some repos
need, so it's a persona rather than a base-profile addition - and, like `press`, also published as
its own OCI image (a third, alongside the base and press images) so `www`'s own devcontainer can
name an image with exactly the toolchain it needs, rather than growing the base image every
devcontainer defaults to, or baking Rust into the press image, which has nothing to do with it.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Build a Rust crate graph with native dependencies, no setup step (Priority: P3)

An engineer or AI agent working in a Rust repo (`www.intellectualfrontiers.com` specifically)
activates the `rust` persona (or pulls the `workspaces-host-v3-rust` image), then runs `cargo
build`/`cargo test`/`cargo task <name>` with no further install step, including for a dependency
graph that compiles C/assembly (`aws-lc-sys`, `ring`) as part of its own build.

**Why this priority**: Narrower audience than spec 024's base-profile additions - a persona/
third-image tier, the same as `press`/`compliance`/`media`, not something every engineer needs.

**Independent Test**: With the `rust` persona activated (or inside the `workspaces-host-v3-rust`
image), every acceptance command in the Done Means section below succeeds, including a `cargo
build` of a crate depending on `reqwest` with the `rustls` feature.

**Acceptance Scenarios**:

1. **Given** no persona activated, **When** `doctor --all` runs, **Then** `rustc`/`cargo`/`cc`/etc.
   (rust's marker tools) report as optional, pointing at `ws-persona activate rust`, not a FAIL.
2. **Given** the `rust` persona activated and `workspaces-host-update` run, **When** `rustc
   --version` (>=1.85), `cargo --version`, `cargo clippy --version`, `rustfmt --version`,
   `rust-analyzer --version`, `cc --version`, `cmake --version`, and `pkg-config --version` all
   run, **Then** every one succeeds, `$CARGO_HOME` is set to a writable directory under `$HOME`,
   and a fresh crate with `reqwest` (rustls, no default features) added builds successfully.
3. **Given** the `workspaces-host-v3-rust` image, **When** the same commands run inside it with no
   persona-activation step, **Then** every one succeeds (the image bakes this persona in
   directly), and `intellectual-frontiers/www.intellectualfrontiers.com`'s own `cargo test --locked`
   and `cargo task check` both succeed with no variable set by hand.

### Edge Cases

- `rust` is additive like every other persona: activating it changes nothing about the base profile
  or any other persona, and neither existing published image (base, press) changes - only the new,
  third `workspaces-host-v3-rust` image carries this toolchain baked in.
- `rust` and `press` can both be activated together (personas combine) without conflict - neither
  declares a package the other also declares.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A new `rust` persona (`home/profiles/rust.nix`) MUST provide `rustc`, `cargo`,
  `clippy`, `rustfmt`, and `rust-analyzer` from this flake's pinned nixpkgs (not rustup, not a
  second flake input, since the pinned revision already clears the >=1.85 edition-2024 floor),
  plus `stdenv.cc`, `cmake`, `pkg-config`, and `perl` for native crate dependencies.
- **FR-002**: `rust` MUST set `CARGO_HOME` to a writable path under `$HOME` and `RUST_SRC_PATH` to
  nixpkgs' `rustPlatform.rustLibSrc`, via `home.sessionVariables`, so both reach every flavor
  (real host, container, devcontainer) the same way every other persona's session variables do.
- **FR-003**: `rust` MUST be registered in `flake.nix`'s `personaModules` and `pkgs/ws-persona`'s
  persona table.
- **FR-004**: `doctor --all` MUST report rust's tools as optional (pointing at `ws-persona activate
  rust`) when the persona isn't active, and PASS when it is, including a check that `$CARGO_HOME`
  is set and writable.
- **FR-005**: `flake.nix` MUST expose `packages.<system>.oci-image-rust` (base + fish + rust),
  built from the same `oci/default.nix` definition as `oci-image`/`oci-image-press` (via its
  existing `imageName` parameter), and `.github/workflows/container-image.yml` MUST build and
  publish it for both `linux/amd64` and `linux/arm64`, under the same `latest`/`sha-<short-sha>`
  multi-arch tag scheme spec 027 established for the other two images.
- **FR-006**: The documentation book's personas and container-ci chapters, and the README, MUST
  document the `rust` persona and the third published image, consistent with how `press` and its
  image are already documented.

### Key Entities

- **`home/profiles/rust.nix`**: the new persona module.
- **`packages.<system>.oci-image-rust`**: the new flake output FR-005 adds.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `ws-persona activate rust && workspaces-host-update` makes every command in User
  Story 1's Acceptance Scenario 2 succeed, `rustc --version` reporting 1.85 or newer.
- **SC-002**: No persona activated keeps those same commands failing (`command not found`),
  proving the persona is genuinely opt-in on a real host/VM install.
- **SC-003**: `docker pull`/`docker run` of the published `workspaces-host-v3-rust` image, on both
  amd64 and arm64, makes the same commands succeed with zero setup step, verified directly against
  the real published tag, not only a local build.

## Assumptions

- This supersedes spec 027's own Assumptions line ("`media` is... never a third [image]"): that
  statement was about `media` specifically (ruled out there for its own, unrelated weight reasons -
  CTranslate2/ONNX Runtime/OpenBLAS, nothing to do with Rust), not a hard cap on the number of
  published images. A third image is exactly the right shape for a third persona whose own weight
  (a full Rust + C/CMake toolchain) doesn't belong in either existing image.
- `media` stays excluded from all three published images, for the same reason spec 026 already
  gives - unchanged by this spec.
