# Feature Specification: Adopt the Checkout an Editor Opened

**Feature Branch**: `034-adopt-editor-checkout`

**Created**: 2026-10-04

**Status**: Implemented

**Input**: User description: "Every repo lives at `~/workspaces/<host>/<org>/<repo>`, and
`ws-repos ensure` clones every listed repo there, never as a second copy. GitHub Codespaces and a
Dev Container cloned into a volume always open the repo at `/workspaces/<repo>`. Codespaces
ignores bind mounts, so `workspaceMount` can't move it. Please make `ws-start` do what each IF
repo's `.devcontainer/workspace-links.sh` does, before it runs `ws-repos ensure`, or add `ws-repos
adopt [PATH]` and have `ws-start` call it. Also: `status` and `inspect` skip adopted repos; and
`\"fresh\": true` on an adopted repo removes only the link, then clones a duplicate."

## Background

The rule (IF `.github` spec `0026-workspaces` FR-015) is one copy of each repo, in the layout. An
editor that opens `/workspaces/<repo>` breaks it twice: `ensure` clones the opened repo again, and
`../.github` doesn't exist beside the checkout. The IF repos worked around it with
`.devcontainer/workspace-links.sh` on create. This moves that logic into `ws-repos adopt`, and
`ws-start` calls it before `ensure`, so the repos can delete their copy.

I chose a subcommand over inlining it in `ws-start`: it's useful by hand too (a checkout someone
cloned to the wrong place), and `ws-repos` already owns the layout and the config.

Links go two directions. `~/workspaces/<host>/<org>/<repo>` points at the checkout, so `ensure`
finds it (`[ -d ]` follows the link) and pulls it. `<parent>/<other-repo>` points into the layout,
so `../<other-repo>` resolves from the checkout. That second direction matters: tools resolve `..`
against the checkout's physical path, so a link that only existed under `~/workspaces` would be no
help.

`status` used `find -name .git -type d`, which never descends through a symlink, so an adopted repo
vanished from it. Rather than `find -L` (which also wanders into every `node_modules` link and
needs loop guarding), `status` and `inspect` list each symlink under `$WORKSPACES_HOME` that is
itself a repo, and don't follow links any further. `fresh` on such a link is refused: `rm -rf` on
it removes only the link, and the clone after it makes the duplicate `adopt` exists to prevent.
`ensure` pulls it instead and says why.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A Codespace gets one copy and working sibling paths (Priority: P1)

**Independent Test**: `devcontainer up` on `intellectual-frontiers/.github` with its
`workspace-links.sh` and its `postCreateCommand` call removed, then attach: `~/workspaces/
github.com/intellectual-frontiers/.github` is a link to `/workspaces/.github`, the other listed
repos are under `~/workspaces` with links beside `/workspaces/.github`, and `ws-repos status`
lists all of them.

**Acceptance Scenarios**:

1. **Given** a checkout listed in `$WS_REPOS_CONFIG` outside `$WORKSPACES_HOME`, **When**
   `ws-repos adopt` runs in it, **Then** the canonical path becomes a link to it and each other
   listed repo gets a link beside it.
2. **Given** the same, **When** `ws-start` runs, **Then** it adopts before `ensure`, and `ensure`
   pulls the checkout instead of cloning it.
3. **Given** a checkout already at its canonical path, or not listed, **When** `adopt` runs,
   **Then** it changes nothing.
4. **Given** something already exists at a path `adopt` would link, **When** it runs, **Then** it
   leaves that alone and says so.
5. **Given** an adopted repo, **When** `ws-repos status` or `inspect` runs, **Then** it includes
   that repo.
6. **Given** an adopted repo with `"fresh": true`, **When** `ensure` runs, **Then** it refuses the
   re-clone, pulls the checkout, and says so.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `ws-repos adopt [PATH]` (default: the current directory) MUST derive `<host>/<org>/
  <repo>` from the checkout's `origin` URL - https with or without credentials, `ssh://` (port
  dropped), or scp-style `user@host:org/repo` - using shell, git and jq only.
- **FR-002**: `adopt` MUST do nothing when the checkout is not listed in `$WS_REPOS_CONFIG`, or
  already is `$WORKSPACES_HOME/<host>/<org>/<repo>`.
- **FR-003**: Otherwise `adopt` MUST make `$WORKSPACES_HOME/<host>/<org>/<repo>` a symlink to the
  checkout's physical path, and, for every other listed repo, make `<parent of the checkout>/
  <repo-name>` a symlink to `$WORKSPACES_HOME/<that repo>`.
- **FR-004**: `adopt` MUST NOT delete, move or overwrite anything; an existing path is reported
  and left alone. It MUST be safe to run again.
- **FR-005**: `ws-start` MUST run `ws-repos adopt` before `ws-repos ensure` whenever it runs inside
  a git checkout.
- **FR-006**: `ws-repos status` and `inspect` MUST include repos reached through a symlink under
  `$WORKSPACES_HOME`, without following symlinks recursively.
- **FR-007**: `ensure` MUST refuse `"fresh": true` for a repo whose path is a symlink, pull it
  instead, and say which it did.

## Success Criteria *(mandatory)*

- **SC-001**: The IF repos can delete `.devcontainer/workspace-links.sh` and its
  `postCreateCommand` call with no change in result.
