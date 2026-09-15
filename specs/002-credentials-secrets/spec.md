# Feature Specification: Credentials & Secrets Handling

**Feature Branch**: `002-credentials-secrets`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "Safe handling of git identity, database, and API credentials via a
local credentials file applied through home-manager/sops-nix, never exported unscoped to the
shell"

## Background

### Follow-up: prefer `gh`/`glab` OAuth over a token in the credentials file (2026)

Newbies were confused about GitHub/GitLab specifically: `credentials.example` listed
`GITHUB_TOKEN`/`GITLAB_TOKEN` right next to `GIT_NAME`/`GIT_EMAIL`, as if creating a personal
access token were a normal, expected step, and `doctor`'s own WARN message led with "add
GITHUB_TOKEN" before mentioning `gh auth login` at all. In reality `gh auth login`/`glab auth
login` (an OAuth device-flow login, no token to create) is simpler for a newcomer *and*
sufficient on its own - one command authenticates the CLI and git together, which a
`GITHUB_TOKEN` alone does not (FR-008a already required documenting that gap; the mistake was
also treating the token as the default rather than the fallback). A raw `GITHUB_TOKEN`/
`GITLAB_TOKEN` value is only genuinely needed for something *other than* `gh`/`glab` itself: a
script, or a project's own `.envrc` via direnv. Every place this repository mentions GitHub/
GitLab credentials - `credentials.example`, `doctor`'s messages, the generated
`~/workspaces/README.md`, and the docs site - now leads with `gh auth login`/`glab auth login`
and documents the token fields as the secondary, only-if-you-need-it path, not the other way
around.

### Follow-up: `gh auth login` broke once a `GITHUB_TOKEN` had ever been configured (2026)

The edge case below ("an engineer has both run `gh auth login` and filled in `GITHUB_TOKEN`")
assumed the two never actually conflict. One case does: `gh`/`glab` themselves refuse to run their
own interactive `auth login` at all once `GH_TOKEN`/`GITHUB_TOKEN`/`GITLAB_TOKEN` is already
present in the environment (their own upstream behavior, not something this repository controls),
and the per-invocation wrapper (FR-005) was injecting a configured token into *every* invocation of
`gh`/`glab`, `auth login` included - so a token in the credentials file silently broke the one
command meant to set auth up in the first place. Worse, since nothing ever removed a previously
written token file when the corresponding credentials-file line was later blanked or deleted (a gap
FR-003 didn't actually cover, despite writing being update-command's job), a reader who added a bad
or placeholder token, then gave up and deleted it, kept hitting the same broken `gh auth login` -
the wrapper kept injecting the stale file regardless of what the credentials file currently said.
Both gaps are closed now: the wrapper skips injection entirely for `gh auth ...`/`glab auth ...`
(FR-005a), and the update command removes a previously written credential file whose key no longer
appears in the credentials file (FR-003a). The edge case's actual conclusion still holds for every
other `gh`/`glab` subcommand - `gh repo clone`, `gh pr list`, and so on happily use either
`gh auth login`'s stored credentials or a configured `GITHUB_TOKEN`, whichever is present.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fill in one file, get everything configured (Priority: P1)

A new engineer copies a tracked example credentials file to a local, git-ignored location, fills
in their name, email, and whatever tokens they already have (leaving the rest blank), then runs
one update command. Their git identity, database access, and any declared API tokens are applied
without ever hand-editing a Nix file.

**Why this priority**: This is the entire onboarding experience for anything requiring personal
identity or secrets; a confusing or multi-step version of this defeats the "one command" promise
of spec 001.

**Independent Test**: Populate a credentials file with a name, email, and one dummy token; run the
update command; confirm `git config user.name`/`user.email` match and the token is retrievable
only through the documented scoped mechanism, not as an ambient shell variable.

**Acceptance Scenarios**:

1. **Given** a freshly copied, mostly-blank credentials file, **When** the engineer fills in name
   and email and runs the update command, **Then** git identity is applied and every other field
   left blank produces a WARN (not a FAIL) from the environment health check (spec 004).
2. **Given** a credentials file with a database token filled in, **When** the update command runs,
   **Then** the token is written to a private, mode-600 location outside the Nix store and is
   never present as an ambient environment variable in a plain interactive shell.

---

### User Story 2 - Update a credential without touching Nix (Priority: P2)

An engineer needs to rotate an API token. They edit the local credentials file and re-run the
update command; no flake/module changes are needed.

**Why this priority**: Secrets rotate far more often than the shell configuration itself; forcing
a Nix-literate change for a routine rotation would be a usability failure for the non-technical
audience this repository explicitly targets.

**Independent Test**: Change one value in the credentials file, re-run the update command, and
confirm only that value's effect changes (e.g. the decrypted file's contents), with no other
generated configuration touched. Separately, blank or delete a previously set value and re-run the
update command; confirm its per-invocation secret file is gone, not just left holding the old
value.

**Acceptance Scenarios**:

1. **Given** an already-configured environment, **When** the engineer changes one credential value
   and re-runs the update command, **Then** the new value takes effect and no Nix source file is
   modified.
2. **Given** a credential the engineer previously configured, **When** they blank or delete its
   line and re-run the update command, **Then** the per-invocation secret file that credential
   wrote is removed, and any tool that reads it (FR-005) behaves exactly as if that credential had
   never been configured.

---

### User Story 3 - A credential a tool needs, scoped to that tool only (Priority: P2)

A database CLI or an AI coding agent needs a credential to do its job, but the credential must
never be visible to an unrelated process running in the same shell session.

**Why this priority**: This is Constitution Principle III, non-negotiable for a repository whose
explicit purpose includes provisioning environments AI agents operate inside.

**Independent Test**: Start an interactive shell with a declared secret present; confirm `env` does
not list it; confirm the tool that needs it (invoked through its documented wrapper) can still use
it successfully.

**Acceptance Scenarios**:

1. **Given** a declared secret and its consuming tool's wrapper, **When** the wrapper invokes the
   real binary, **Then** the credential is set only for that invocation's process, not inherited by
   the parent shell or sibling processes.

### Edge Cases

- What happens when the credentials file is missing entirely on first run? The update command must
  create it from the tracked example (mode 600) and stop without applying a partial configuration,
  rather than silently proceeding with blank identity.
- What happens when the credentials file has loose permissions (e.g. world-readable)? The update
  command must correct the mode on every run rather than only checking it once.
- What happens when a declared secret's source is missing or fails to decrypt at activation time?
  Activation must fail loudly for that secret rather than silently producing an empty file that a
  consuming tool would treat as "configured."
- What happens when an engineer has both run `gh auth login` and filled in `GITHUB_TOKEN`? Either
  authenticates `gh` for ordinary use (`gh repo clone`, `gh pr list`, ...), so `doctor` (spec 004)
  MUST report PASS from whichever one actually works, never asking the engineer to remove one in
  favor of the other. Running `gh auth login`/`gh auth logout`/`glab auth login` itself is the one
  exception: FR-005a requires the wrapper to never inject a configured token into an `auth`
  subcommand, specifically so a configured `GITHUB_TOKEN`/`GITLAB_TOKEN` can never block that
  command from managing `gh`/`glab`'s own stored credentials.
- What happens when a key in the credentials file is blanked or its line removed, after an earlier
  run already wrote it to its per-invocation secret file? FR-003a requires the update command to
  remove that file too, in the same run - a wrapped CLI (FR-005) MUST NOT keep receiving a
  credential that no longer appears in the credentials file.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A tracked `credentials.example` file MUST exist at the repository root, documenting
  every recognized key in plain `KEY=value` form.
- **FR-002**: The update command MUST create the real credentials file (outside version control,
  mode 600) from that example on first run if it does not exist, and MUST stop without applying
  configuration until the engineer has had a chance to fill it in.
- **FR-003**: The update command MUST parse the credentials file as plain `KEY=value` (never
  sourced as a shell script), writing git identity into the git-config-generation module's inputs
  and every other recognized value into a private, mode-600 location outside the Nix store.
- **FR-003a**: On every run, the update command MUST remove any previously written per-invocation
  secret file whose key is no longer present (blanked or deleted) in the current credentials file -
  a rotated-away or removed credential MUST NOT keep being read by a wrapped CLI (FR-005)
  indefinitely just because an earlier run once wrote it.
- **FR-004**: The update command MUST re-assert mode 600 on the credentials file on every run,
  before applying any configuration.
- **FR-005**: The system MUST NOT export any declared secret as an ambient environment variable
  available to a whole interactive shell session; a tool that needs a secret MUST receive it only
  for its own invocation, via a documented per-invocation wrapper.
- **FR-005a**: The per-invocation wrapper for `gh`/`glab` (FR-008) MUST NOT inject a configured
  `GITHUB_TOKEN`/`GH_TOKEN`/`GITLAB_TOKEN` when the CLI's own first argument is `auth` - `gh
  auth login`/`gh auth logout`/`glab auth login` and the rest of that subcommand family MUST always
  reach the real, unwrapped CLI so they can manage its own stored credentials, unaffected by
  whatever the credentials file currently holds. Every other subcommand keeps receiving the
  configured token as FR-008a documents.
- **FR-006**: The system MUST support an advanced, opt-in path (a sops-based module) for
  engineers who want secrets encrypted at rest and decrypted only at activation time, for cases
  the plain credentials file does not cover (e.g. a shared team secret rather than a personal
  one).
- **FR-007**: The environment health check (spec 004) MUST report the credentials file's
  existence and permissions, and MUST distinguish "field left blank" from "field still holding
  the placeholder value" as two different WARN messages.
- **FR-008**: `credentials.example` MUST include `GITHUB_TOKEN`/`GITLAB_TOKEN`, clearly labeled as
  optional and secondary to `gh auth login`/`glab auth login` (FR-008a) rather than presented
  alongside `GIT_NAME`/`GIT_EMAIL` as an expected default, and the base profile MUST install
  `gh`/`glab`, each wrapped so a configured token is exported only for that CLI's own invocation
  (the same per-invocation mechanism FR-005 requires) — needed for spec 003's `ws-repos` to be
  practically usable against private repositories, not a separate concern.
- **FR-008a**: `gh auth login`/`glab auth login` (an OAuth device-flow login, no token to create)
  MUST be documented as the preferred, default way to authenticate GitHub/GitLab everywhere this
  repository mentions it - `credentials.example`, `doctor`'s own check messages, the generated
  `~/workspaces/README.md`, and the docs site - since one command authenticates both the
  `gh`/`glab` CLI and git itself (including the `--hostname` form for a private, self-hosted
  GitLab instance), which a `GITHUB_TOKEN`/`GITLAB_TOKEN` credential alone does not. A raw token
  in the credentials file MUST be documented as the secondary path, only for a case that
  genuinely needs the raw value outside `gh`/`glab` (a script, a project's own `.envrc`), never as
  the first or only option shown.
- **FR-009**: The base profile MUST install `gitleaks`, so an engineer can scan a repository for
  accidentally-staged secrets before committing, as a concrete backstop alongside a project's own
  `.gitignore` and reviewing `git diff --staged`.
- **FR-010**: Every interactive shell MUST check, at most once per calendar day (tracked via a
  stamp file, checked in the background so shell startup is never blocked), whether
  `$WORKSPACES_HOST_REPO`'s `origin/main` has moved, and print an informational nudge naming the
  commit count and the update command if so — this MUST NOT run the update itself, only inform.

### Key Entities

- **Credentials file**: the engineer's local, git-ignored `KEY=value` file holding their personal
  identity and any tokens they choose to provide.
- **Declared secret**: one resolved credential — a source (plain value or sops-encrypted file)
  plus its private, decrypted-output path.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An engineer can go from a blank credentials file to a fully-configured git identity
  in under two minutes, with no Nix knowledge required.
- **SC-002**: No secret declared through this mechanism ever appears in the output of a plain
  `env` command in an interactive shell.
- **SC-003**: Rotating a credential requires editing exactly one file and re-running exactly one
  command, with zero Nix source changes.
- **SC-004**: `gh auth login`/`glab auth login` succeed whether or not `GITHUB_TOKEN`/`GITLAB_TOKEN`
  is configured in the credentials file - verified directly, not assumed, by exporting a known,
  invalid token into the wrapped CLI's own secret file and confirming an `auth login`/`auth status`
  invocation still reaches the real, unwrapped binary.
- **SC-005**: Blanking or deleting a previously configured credential's line, then re-running the
  update command, leaves no trace of it in the per-invocation secrets directory - verified by
  checking the file is actually gone, not merely that the credentials file no longer mentions it.

## Assumptions

- Personal secrets (a single engineer's own tokens) go through the plain credentials file; only
  genuinely shared team secrets need the sops-based advanced path.
- Decryption key material for the advanced sops path is provisioned out-of-band by the engineer,
  not managed by this repository.
