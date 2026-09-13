# Feature Specification: Core Flake + Home-Manager Base

**Feature Branch**: `001-core-flake-shell`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "Nix flake + home-manager base providing a reproducible bash shell,
oh-my-posh prompt, and pinned everyday CLI tools identically across hosts and containers"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One command gives me a working shell (Priority: P1)

An engineer on a fresh Linux, macOS, or WSL2 machine runs one build-and-activate command against
this flake and gets a configured interactive bash shell: a prompt that shows their git branch and
directory context, sensible history/completion behavior, and git already configured from their
own declared identity.

**Why this priority**: This is the entire value proposition of the repository. Nothing else
matters if this doesn't work.

**Independent Test**: On a clean account, build `homeConfigurations.<name>.activationPackage` and
run its `activate` script; open a new shell and confirm the prompt renders and `git config
user.name` returns the configured value.

**Acceptance Scenarios**:

1. **Given** a clean account with only Nix installed, **When** the engineer builds and activates
   this flake's home-manager configuration, **Then** a new interactive shell is bash, shows the
   oh-my-posh prompt, and has git identity configured from the flake's declared options.
2. **Given** an already-activated profile, **When** the engineer re-runs activation with no
   changes, **Then** activation succeeds idempotently with no errors and no duplicated
   configuration.

---

### User Story 2 - The exact same setup on a second machine (Priority: P1)

The same engineer activates the same flake commit on a second machine (a different OS, or a
teammate's machine, or a CI runner) and gets a byte-for-byte identical set of tool versions and
shell configuration, with no manual "also install X" step.

**Why this priority**: Reproducibility across machines is the constitutional promise
(Principle I); without it this is just a personal dotfiles repo.

**Independent Test**: Activate the same flake commit on two different clean environments (e.g.
two containers) and diff the resulting `home.packages` closures and generated dotfiles; they must
match except for machine-specific identity values.

**Acceptance Scenarios**:

1. **Given** the same flake commit, **When** activated on two different clean machines, **Then**
   every pinned package resolves to the identical Nix store path (same version, same build) on
   both.

---

### User Story 3 - Pull to update, one command to reapply (Priority: P2)

An engineer who already has this environment wants to pick up an improvement pushed to the
repository: `git pull`, then re-run the same activation command, with no other steps.

**Why this priority**: Keeping many machines in sync is what makes the shared-repository model
worth it instead of everyone hand-tuning their own dotfiles.

**Independent Test**: Change a tracked module (e.g. add a package), commit, `git pull` on an
already-activated machine, re-activate, and confirm the new package is on `PATH` with no manual
cleanup step.

**Acceptance Scenarios**:

1. **Given** an activated profile and a new commit that adds a package, **When** the engineer
   pulls and re-activates, **Then** the new package is available with no leftover state from the
   previous generation blocking it.

### Edge Cases

- What happens when activation is re-run with the account's pre-existing, non-symlink
  `~/.bashrc`/`~/.profile` already present (a brand-new Debian/WSL account ships these by
  default)? Activation must not fail outright; existing non-managed dotfiles must be backed up
  automatically rather than blocking the install.
- What happens when the engineer has not set a git identity yet? The shell must still activate
  successfully; git identity is reported as unset by the environment health check (spec 004), not
  a hard activation failure.
- How does the system behave on an architecture/OS combination the flake does not target (e.g.
  32-bit)? The flake evaluation must fail clearly at build time rather than producing a broken
  partial activation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST provide a `flake.nix` at its root defining at least one
  home-manager configuration output buildable with `home-manager switch --flake .#<name>` (or the
  equivalent `nix build .#homeConfigurations.<name>.activationPackage` + `./result/activate`
  path, for accounts without home-manager itself pre-installed).
- **FR-002**: The flake MUST pin all inputs (nixpkgs, home-manager, and any other flake inputs)
  via `flake.lock`, such that activating the same commit on different machines produces the same
  closure.
- **FR-003**: The home-manager configuration MUST set bash as the configured interactive login
  shell, with all shell configuration (prompt, aliases, history behavior, completion) managed
  declaratively through home-manager — no hand-maintained dotfile outside the module.
- **FR-004**: The home-manager configuration MUST install and configure oh-my-posh with a
  checked-in theme, wired into the bash prompt.
- **FR-005**: The home-manager configuration MUST enable direnv with the nix-direnv extension,
  integrated with bash so per-directory `.envrc` files load automatically after the standard
  direnv trust step.
- **FR-006**: The home-manager configuration MUST expose declarative options for git identity
  (user name, user email, and optionally a signing key) and MUST render a generated
  `~/.gitconfig` from those options, including safe-default settings (e.g.
  `init.defaultBranch`, `pull.rebase`).
- **FR-007**: The home-manager configuration MUST install a small, pinned set of everyday CLI
  tools (at minimum: a modern `ls`/`cat` replacement, `ripgrep`, `fd`, fuzzy history/file search,
  and frecency-based directory jumping) so the shell feels immediately productive without an
  engineer installing anything themselves.
- **FR-008**: The flake MUST NOT depend on Homebrew, pkgx, eget, mise, SDKMAN!, or chezmoi at any
  point in provisioning — Nix + home-manager is the sole reproducibility engine.
- **FR-009**: `nix flake check` MUST pass against the flake with no errors.
- **FR-010**: The flake MUST support Linux (including WSL2) and macOS as evaluation/build targets
  for the home-manager configuration, even if only one is exercised in a given CI run.
- **FR-011**: Activation MUST set `HOME_MANAGER_BACKUP_EXT` (or an equivalent mechanism) so a
  fresh account's pre-existing, non-symlink dotfiles are backed up automatically rather than
  blocking activation.

### Key Entities

- **Home-manager profile**: a named `homeConfigurations` output bundling the bash/oh-my-posh/
  direnv/git configuration and the core CLI toolset for one target user/machine class.
- **Git identity options**: the declarative options (name, email, signing key) a profile supplies
  to the git-config-generation module.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new engineer goes from a clean account to a working, prompt-showing, git-configured
  bash shell in one activation command, with zero manual follow-up steps beyond filling in their
  own identity.
- **SC-002**: Two machines activating the same commit produce identical package closures (verified
  by comparing resolved store paths), with the only differences being machine-specific identity
  values.
- **SC-003**: Re-running activation with no changes is idempotent: no errors, no duplicated shell
  configuration, no drift in the generated dotfiles.
- **SC-004**: `nix flake check` passes with zero errors on every supported system.

## Assumptions

- Nix (with the `flakes` and `nix-command` experimental features) is already installed on the
  target machine; installing Nix itself is covered by the top-level installer, not this spec.
- Engineers are comfortable running one documented command in a terminal; a GUI installer is out
  of scope.
- fish-like interactive conveniences (autosuggestions, syntax highlighting) are approximated with
  bash-native tooling rather than requiring fish itself, per the constitution's bash default.
