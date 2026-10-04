# Feature Specification: `ws-start` Devcontainer Bootstrap

**Feature Branch**: `028-ws-start-devcontainer-bootstrap`

**Created**: 2026-10-03

**Status**: Implemented

**Input**: User description: "A first-run command for devcontainers: check gh auth, log in if
needed (wiring up git's credential helper), then ws-repos ensure against the repo's own list -
run as `postAttachCommand`, not `postCreateCommand`, since creating the container can't clone a
private repo before a login exists."

## Background

Every Intellectual Frontiers repository's own `.devcontainer/devcontainer.json` will reference the
image this flake publishes, plus its own `.devcontainer/ws-repos.json` (a repo list in exactly the
format `pkgs/ws-repos` already reads). What's missing is the one command that turns "container
exists" into "logged in and every repo cloned" - and it has to run at `postAttachCommand` time, not
`postCreateCommand`: creating the container happens before any human (or Codespaces) has attached
to it, so there's no GitHub login yet, and `ws-repos ensure` against a private repo would fail at
exactly that point.

`gh auth login`'s device-code flow works interactively in a plain terminal, VS Code's integrated
terminal, and a Codespace alike - confirmed directly, not assumed - so this doesn't need a
different code path per flavor. `pkgs/ws-repos` already honors `$WS_REPOS_CONFIG` (its own
documented default, `$WORKSPACES_HOME/ws-repos.json`, overridable); `ws-start` doesn't need any new
logic for that - a devcontainer.json that sets `WS_REPOS_CONFIG=/workspaces/<repo>/.devcontainer/
ws-repos.json` via `remoteEnv` already gets exactly that file read, with zero changes to
`ws-repos` itself.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Attach to a devcontainer, get a working checkout (Priority: P2)

An engineer or AI agent attaches to an IF repository's devcontainer (local, or Codespaces) for the
first time, and ends up authenticated to GitHub with every repo in that devcontainer's own
`ws-repos.json` cloned, with no manual step beyond answering the device-flow login prompt.

**Why this priority**: This is the concrete mechanism that makes "every IF repo, no setup step
after clone" true for devcontainers/Codespaces specifically - the audience most likely to be a
non-technical user with no Nix/git tooling of their own.

**Independent Test**: Attach to a devcontainer whose `postAttachCommand` runs `ws-start`, with no
prior `gh` login; confirm it prompts the device-flow login, then clones every repo in
`$WS_REPOS_CONFIG`.

**Acceptance Scenarios**:

1. **Given** no existing `gh` authentication, **When** `ws-start` runs, **Then** it starts `gh auth
   login`'s device flow, and on success wires git to use `gh` as its credential helper
   (`gh auth setup-git`).
2. **Given** an already-authenticated environment (a Codespace's own pre-provisioned token, or a
   second attach after User Story 1's first run), **When** `ws-start` runs, **Then** the
   authentication step is a near-instant no-op - no login prompt.
3. **Given** either case, **When** `ws-start` finishes, **Then** `ws-repos ensure` has run against
   `$WS_REPOS_CONFIG` (or its default), and one summary line reports what happened (authentication
   state, `ws-repos ensure` outcome) and what to do next if something didn't complete.

### Edge Cases

- `gh auth login` declined or interrupted: `ws-start` MUST still finish (report the incomplete
  state in its summary line and suggest re-running `gh auth login`/`ws-start`) rather than aborting
  the rest of the script - `ws-repos ensure` still runs for whatever repos don't need private
  authentication.
- No `$WS_REPOS_CONFIG` and no `~/workspaces/ws-repos.json` yet: `ws-repos ensure`'s own existing
  "no config found" message covers this; `ws-start` doesn't duplicate that logic.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A new `ws-start` command (`pkgs/ws-start`) MUST check `gh auth status`; if not
  authenticated, run `gh auth login`, then (on success, or if already authenticated) run `gh auth
  setup-git` so git uses `gh`'s stored credentials.
- **FR-001a** (spec 034): Before `ws-repos ensure`, `ws-start` MUST run `ws-repos adopt` when it
  runs inside a git checkout, so a checkout an editor opened outside `~/workspaces` is linked into
  the layout instead of cloned a second time.
- **FR-002**: `ws-start` MUST run `ws-repos ensure` afterward, with no new configuration logic of
  its own - `ws-repos`'s existing `$WS_REPOS_CONFIG` handling already covers "point this at the
  repo's own `.devcontainer/ws-repos.json`."
- **FR-003**: `ws-start` MUST be idempotent (safe to run on every attach, not only the first) and
  end by printing one summary line stating what it did and, if anything is incomplete, what to do
  next. Amended by spec 033: the summary names every repo that failed, a next-step line follows
  it, and `ws-start` exits non-zero when `ensure` did.
- **FR-004**: `ws-start` MUST be a base-profile tool (`home/tools.nix`), available on every flavor,
  not gated behind a persona.
- **FR-005**: Both of this repository's own devcontainer configs (`.devcontainer/devcontainer.json`,
  `.devcontainer/fish/devcontainer.json`) MUST run `ws-start` as `postAttachCommand` - the concrete
  self-example other IF repos' own devcontainer configs copy.
- **FR-006**: The documentation book MUST document `ws-start` and the `postAttachCommand`
  convention it establishes for other repositories' own devcontainer configs.

### Key Entities

- **`pkgs/ws-start`**: the new command.
- **`postAttachCommand`**: the devcontainer lifecycle hook `ws-start` runs under - distinct from
  `postCreateCommand` (spec 021's `doctor` health check), which runs before any login exists.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Attaching to this repository's own devcontainer with no prior `gh` login completes
  `ws-start` with a clear summary line, and a second attach reports the already-authenticated,
  already-cloned state with no repeated login prompt.
- **SC-002**: An IF repository that sets `WS_REPOS_CONFIG` in its own `devcontainer.json` and runs
  `ws-start` as `postAttachCommand` gets every repo in its own `ws-repos.json` cloned, with zero
  changes needed in this flake's own `ws-start`/`ws-repos` code.

## Assumptions

- `glab`/GitLab authentication is explicitly out of scope for `ws-start` - the request scoped this
  command to GitHub login specifically (`gh auth login`/`setup-git`); a repo that also needs GitLab
  repos still runs `glab auth login` itself, the same manual step `doctor`/the documentation book
  already describe.
