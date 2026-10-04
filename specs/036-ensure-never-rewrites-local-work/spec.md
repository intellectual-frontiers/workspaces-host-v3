# Feature Specification: `ws-repos ensure` Never Rewrites Local Work

**Feature Branch**: `036-ensure-never-rewrites-local-work`

**Created**: 2026-10-04

**Status**: Implemented

**Input**: Reported from the IF `.github`/`eidolon`/`www` session testing `sha-f6659cc`: "`ws-repos
ensure` runs `git pull` on every repo, including the checkout `ws-start` just adopted, which is
the working copy the person is editing. git's config in the image makes that pull a rebase. My
checkout had local commits that conflicted with upstream, so the attach failed with 'could not
apply ae4b593...' and left the working copy mid-rebase. Change it to: fast-forward only, report
and skip anything diverged; skip the update entirely for the adopted checkout, fetch at most;
treat a dirty working tree the same way, no autostash."

## Background

This profile's git config sets `pull.rebase = true` and `rebase.autoStash = true`
(`home/git.nix`). That's a fine default for a person typing `git pull`. It's the wrong thing for a
command that runs on every devcontainer attach: `ensure` pulled every repo, so a reattach with
unpushed commits that conflicted upstream started a rebase and stopped halfway through it, on the
exact working copy someone was editing. Spec 034 made this worse by design, because adopting the
editor's checkout is what put it in `ensure`'s path.

`ensure` now fetches and fast-forwards, and leaves alone anything a fast-forward can't handle. It
never runs `pull`, `rebase`, `merge` without `--ff-only`, or `stash`. The adopted checkout (a
symlink under `$WORKSPACES_HOME`) is only fetched, so `status` shows how far behind it is without
anything touching its tree. "Left alone" isn't a failure: the repo is fine, it just has work in it
that the person has to reconcile, so it goes in the summary under its own heading and `ensure`
still exits 0.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reattaching never disturbs unpushed work (Priority: P1)

**Independent Test**: In a devcontainer whose opened checkout has an unpushed commit conflicting
with origin, run `ws-start`: that checkout's `git status` and `HEAD` are unchanged, no rebase is in
progress, the other repos still clone and link, and the summary names the checkout and why.

**Acceptance Scenarios**:

1. **Given** an adopted checkout, **When** `ensure` runs, **Then** it fetches it and changes
   nothing else.
2. **Given** a clean clone that is only behind upstream, **When** `ensure` runs, **Then** it is
   fast-forwarded.
3. **Given** a clone with local commits and upstream commits (diverged), **When** `ensure` runs,
   **Then** it is left as it was and reported with both counts.
4. **Given** a clone with uncommitted changes to tracked files, **When** `ensure` runs, **Then** it
   is left as it was, nothing is stashed, and it is reported.
5. **Given** a clone whose branch has no upstream, **When** `ensure` runs, **Then** it is left as
   it was and reported.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `ensure` MUST update an existing clone only by `git fetch` followed by `git merge
  --ff-only`, and MUST NOT run `git pull`, a rebase, a non-fast-forward merge, or `git stash`.
- **FR-002**: For a repo whose path under `$WORKSPACES_HOME` is a symlink (an adopted checkout),
  `ensure` MUST only fetch.
- **FR-003**: `ensure` MUST leave unchanged, and report with the reason, a repo that has
  uncommitted changes to tracked files, has diverged from its upstream, or has no upstream.
- **FR-004**: A repo left unchanged under FR-002/FR-003 MUST NOT count as a failure; `ensure`
  lists them in its closing summary, and, when `$WS_REPOS_SKIPPED_FILE` is set, appends one
  "`<repo>: <reason>`" line per repo to it.
- **FR-005**: `ws-start` MUST print one "not updated" line per repo `ensure` left unchanged.

## Success Criteria *(mandatory)*

- **SC-001**: No `ws-start` or `ensure` run leaves any repo with a rebase or merge in progress, or
  with a new stash entry.

## Assumptions

- Untracked files don't block the update: `merge --ff-only` itself refuses, leaving the tree as it
  was, if the fast-forward would overwrite one, and that refusal is reported as a failure with
  git's reason.
