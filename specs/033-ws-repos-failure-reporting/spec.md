# Feature Specification: `ws-repos`/`ws-start` Failure Reporting

**Feature Branch**: `033-ws-repos-failure-reporting`

**Created**: 2026-10-04

**Status**: Implemented

**Input**: User description: "`ws-repos ensure` must exit non-zero when any repo fails to clone or
pull, and name each failure. Today a failed clone still ends with `ws-start: ... ws-repos ensure:
ok`. Print git's own reason for a failed clone. 'not a valid managed git URL?' misleads on an auth
or network failure. When login did not complete, `ws-start` should still try (public repos clone
without it), but its summary must say which repos failed and that `gh auth login` then `ws-start`
is the fix."

## Background

`ensure` ran each repo inside a `jq | while` pipeline, printed "clone failed ... (not a valid
managed git URL?)", and returned 0. So `ws-start` said `ok` after a failed clone. The guess in
parentheses was wrong far more often than right: in a devcontainer before login, the real cause is
"could not read Username"; elsewhere it's "Repository not found" (no access) or "Could not resolve
host" (offline). Each needs a different fix, so the tool should print git's reason and stop
guessing.

Failures go to a temp file, not a variable, because the pipeline runs in a subshell and a
variable set there never reaches the end of `cmd_ensure`. `ws-start` learns the failed repo names
through `$WS_REPOS_FAILED_FILE`, a file `ensure` appends each name to, rather than by parsing
`ensure`'s output.

`ws-start` sets `GIT_TERMINAL_PROMPT=0`. Without it, a private repo before login can stop at a
username prompt nobody is watching (a `postAttachCommand` in a Codespace). With it, the clone
fails at once with git's own reason, and the summary says what to do.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A failed clone is reported as a failure (Priority: P1)

**Independent Test**: `ensure` against a list with one public and one private repo, not logged in:
the public one clones, the private one's line shows git's "could not read Username" reason, the
closing summary names it, and the exit status is non-zero.

**Acceptance Scenarios**:

1. **Given** any repo fails to clone or pull, **When** `ws-repos ensure` finishes, **Then** it
   prints one line per failed repo with git's own stderr, and exits non-zero.
2. **Given** every repo succeeds, **When** `ensure` finishes, **Then** it prints
   `ws-repos ensure: ok` and exits 0.
3. **Given** login did not complete and a repo failed, **When** `ws-start` finishes, **Then** its
   summary names the failed repos and says to run `gh auth login`, then `ws-start`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `ws-repos ensure` MUST keep going after a failed clone or pull, then exit non-zero
  if any failed, listing each failed repo with git's reason.
- **FR-002**: The reason MUST be git's own stderr, not a guess.
- **FR-003**: When `$WS_REPOS_FAILED_FILE` is set, `ensure` MUST append each failed repo's name
  to it.
- **FR-004**: `ws-start` MUST still run `ensure` when login did not complete, and its summary MUST
  name each failed repo; when login did not complete and a repo failed, it MUST say `gh auth
  login` then `ws-start` is the fix.
- **FR-005**: `ws-start` MUST exit non-zero when `ensure` did.
- **FR-006**: `ws-start` MUST run git with `GIT_TERMINAL_PROMPT=0`.

## Success Criteria *(mandatory)*

- **SC-001**: No run of `ws-start` with a failed clone ends with `ws-repos ensure: ok`.

## Assumptions

- A non-zero `postAttachCommand` is the honest outcome when a repo didn't clone. The container is
  still usable; the devcontainer CLI and VS Code report the failure instead of hiding it.
- This amends spec 028's FR-003: the summary is now a few lines when something failed, one when
  nothing did.
