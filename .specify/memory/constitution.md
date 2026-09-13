# Workspaces Host v3 Constitution

## Core Principles

### I. Reproducible by Lockfile, Not by Drift
Every tool, package, and shell configuration this project provisions MUST be pinned by a
lockfile (`flake.lock`) rather than resolved at install time against a mutable upstream (a
rolling Homebrew formula, an untracked version manager, an imperative script that mutates
whatever state a host happens to be in). A fresh `nix develop` or `home-manager switch` against
a given commit MUST produce a byte-for-byte identical closure on any machine, any day.
Imperative "install this, then patch that" bootstrapping is prohibited; if a tool cannot be
expressed declaratively in the flake, it does not belong in this repository until it can.

### II. Ephemeral and Disposable by Default
Sandboxes provisioned from this repository are treated as disposable: destroy and rebuild
rather than patch in place, and never assume prior state survives a rebuild. Every feature MUST
be designed so that `home-manager switch` (or the equivalent container/image build) from a clean
checkout produces a fully working environment with no manual recovery steps. Anything that would
make an environment un-reproducible if wiped — an untracked local edit, a manually-run one-off
command, state that lives only on one host and nowhere else — is a defect to be fixed, not a
workaround to be documented.

### III. Secrets Never Touch the Agent's Shell Unscoped
Secrets (API keys, tokens, credentials) MUST be resolved through a scoped secrets mechanism at
the point of use, never exported as ambient environment variables available to an entire shell
session or to an AI coding agent's unscoped process tree. Per-project secret scoping
(direnv-style) is required wherever a secret is needed; a feature that widens secret exposure
beyond the project or command that needs it MUST be rejected in review. This is non-negotiable
given this repository's explicit purpose of provisioning environments that AI coding agents
operate inside.

### IV. Container and Cloud-Harness Parity is Required, Not Optional
A persistent host (Linux, macOS, WSL) is one provisioning target among several — a container
image and a cloud agent-harness session are equally first-class targets, built from the same
flake outputs. A feature that only works on a persistent host, or that cannot be built as an OCI
image from the same closure, is incomplete. "Works in my sandbox" without a corresponding
container build is not a passing state for any feature in this repository.

### V. Simplicity Over Completeness
This repository is a deliberate fresh start, not a continuation of prior implementation
decisions. Every feature MUST be built to the simplest design that satisfies its spec today, not
to accommodate speculative future needs or to preserve a prior version's incidental choices. A
capability that is not yet load-bearing for the core promise (the same environment, everywhere)
belongs in a written spec in the backlog, not in code, until it is actually scheduled for
implementation. Carrying forward a prior version's tool, workaround, or abstraction MUST be
justified on its own merits, never by "that's how it was done before."

### VI. Documentation Voice
All prose documentation this repository publishes for a human to read — `README.md`, any `docs/`
guide, and the narrative sections of a spec (`Background`, rationale asides, `Assumptions`) — MUST
follow [`.specify/memory/writing-style.md`](writing-style.md). This does NOT apply to a
spec's or plan's structured, testable sections (Functional Requirements, Acceptance Scenarios,
Success Criteria), which MUST stay in SpecKit's own precise, third-person, testable requirement
language ("The system MUST...") — that precision is what makes a requirement verifiable, and the
style guide's first-person, conversational voice would undermine it there. A documentation change
that violates the style guide MUST be fixed in the same change that introduces it, not deferred.

## Additional Constraints

- **Toolchain**: Nix flakes + home-manager are the single reproducibility engine for this
  repository. General-purpose package/version managers (Homebrew, pkgx, eget, mise, SDKMAN!,
  chezmoi, etc.) are not to be introduced; where a capability needs a tool like that, the
  implementation is a flake input or home-manager module, not a port of the tool itself.
- **Shell UX**: bash is the default interactive shell, configured entirely through home-manager
  (not dotfile templating), so nothing copy-pasted from elsewhere ever needs translating.
- **Per-project env scoping**: direnv with `nix-direnv` is the standard mechanism for
  project-local environment and secret scoping.
- **OCI builds**: container images are built from the same flake outputs as the host environment
  (via `nix2container` or `dockerTools`), never from a hand-maintained Dockerfile that could
  drift from the flake.

## Development Workflow

- Every feature follows the Spec Kit lifecycle: `/speckit-specify` → `/speckit-plan` →
  `/speckit-tasks` → `/speckit-implement`, each producing its own PR against `main`.
  `/speckit-clarify`, `/speckit-analyze`, and `/speckit-checklist` are used where they reduce
  ambiguity or risk, at the implementer's discretion.
- Specs are tiered explicitly as **core** (implemented now — the minimum needed for Principle IV's
  promise to hold: shell/prompt, credentials, multi-repo workspace management, environment
  health-check/rollback, and container parity) or **backlog** (specified in full, but not
  implemented until scheduled). A backlog spec MUST be implementable on its own without
  requiring a rewrite of core specs.
- Each spec is scoped as a single reviewable PR. A spec too large to review as one PR MUST be
  split into smaller specs before implementation begins.

## Governance

This constitution supersedes all other project practices. Amendments require: a documented
rationale, a version bump under the semantic versioning policy below, and an update to any
templates or guidance that the amendment makes inconsistent.

- **MAJOR**: backward-incompatible governance or principle removal/redefinition.
- **MINOR**: a new principle or section added, or materially expanded guidance.
- **PATCH**: clarifications, wording, or non-semantic refinements.

All specs and plans MUST verify compliance with this constitution before implementation begins;
any deviation must be justified in the plan's Complexity Tracking section or rejected.

**Version**: 1.1.0 | **Ratified**: 2026-09-13 | **Last Amended**: 2026-09-13
