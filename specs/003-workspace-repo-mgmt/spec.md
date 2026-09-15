# Feature Specification: Workspace Repository Management (`ws-repos`)

**Feature Branch**: `003-workspace-repo-mgmt`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "mgit tool to clone and update many git repositories into one
predictable ~/workspaces layout and run the same command across many of them"

## Background

This feature is a POSIX-shell port of the "mGit" pattern from
[strategy-coach/workspaces](https://github.com/strategy-coach/workspaces) (`mgit.ts` /
`ws-ensure.ts`): the same governed `<git-host>/<org>/.../<repo>` directory convention, the same
idempotent clone-or-pull semantics, and the same VS Code `*.code-workspace` multi-root
composition trick. Two things are named differently from upstream, deliberately:

- **The command is `ws-repos`, not `mgit`.** Unrelated third-party tools are also named `mgit`;
  naming this command differently avoids that collision entirely. This is a naming choice only —
  the underlying pattern, directory convention, and file-matching behavior are unchanged.
- **The workspace file suffix stays `*.mgit.code-workspace`.** That string comes from upstream
  `mgit.ts`'s own hardcoded `strictVsCodeWsPathMatchers()`, not from this tool's name — keeping it
  means a `*.mgit.code-workspace` file written for the original mGit tooling (or for v2's `mgit`)
  is still recognized here unchanged.

A prior port (workspaces-host-v2's `mgit`, and v3's own first pass) simplified upstream's
`mGitStatus()` down to dirty/ahead/behind/no-upstream/clean, dropping upstream's stash count and
stuck-`index.lock` detection, and used a strict-JSON `jq` parse of `*.code-workspace` files where
upstream uses a comments-tolerant JSONC parser. This revision closes those gaps (FR-004a, FR-008).

A second revision fixed a real accuracy gap in `status`'s ahead/behind numbers: they came from
`git rev-list` against the local copy of the upstream ref, which only reflects the last time
anything happened to fetch it - a repo could sit there reporting "clean" when it was actually
several commits behind the real remote. `status` now fetches from each repo's upstream first, so
"needs a pull" means the reader can trust it, at the cost of `status` becoming a network operation
(unlike `ensure`/`inspect`, which stay local-only reads once a repo is cloned). The same revision
added color (one icon and one color per line, auto-disabled for a non-terminal, `NO_COLOR`, or
`TERM=dumb`, matching `doctor`'s own convention) and a closing tally of up-to-date/needs-a-pull/
needs-attention counts, so a reader scanning many repos does not have to read every line; and
switched every printed repo path from an absolute path under `$WORKSPACES_HOME` to a path relative
to the directory `ws-repos status` was actually run from, which is shorter and matches how a
reader already thinks about "where am I relative to this repo" day to day.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One predictable place for all my repos (Priority: P1)

An engineer lists the repositories they work on in one config file and runs a single command;
every repo is cloned (or updated, if already present) into one predictable folder layout under
`~/workspaces`.

**Why this priority**: A predictable layout is what lets a human, a teammate, CI, and an AI agent
all refer to "the repo" the same way regardless of whose machine they're on.

**Independent Test**: Populate the config with two repo entries on a clean `~/workspaces`; run the
ensure command; confirm both are cloned to their expected paths.

**Acceptance Scenarios**:

1. **Given** a config listing repos not yet cloned, **When** the engineer runs the ensure command,
   **Then** every listed repo is cloned to its predictable path under `~/workspaces`.
2. **Given** a config listing repos already cloned, **When** the engineer re-runs the ensure
   command, **Then** each repo is updated (pulled) in place rather than re-cloned, unless the
   config explicitly marks that entry for a fresh clone.

---

### User Story 2 - Know the state of everything at a glance (Priority: P1)

An engineer wants to know, across every repo under `~/workspaces`, which are dirty, ahead, behind,
have no upstream, have untracked files, are stuck with a stale lock, or have stashed changes —
without visiting each one individually.

**Why this priority**: Losing track of uncommitted (or stashed, and forgotten) work across many
repos is the exact failure mode this tool exists to prevent.

**Independent Test**: Create a dirty repo, a repo with only untracked files, a repo with a stash,
and a clean repo under `~/workspaces`; run the status command; confirm each is reported correctly
and distinctly.

**Acceptance Scenarios**:

1. **Given** several repos under `~/workspaces` in different states, **When** the engineer runs
   the status command, **Then** each repo's state (dirty / untracked / ahead / behind /
   no-upstream / locked / stash count / clean) is reported.

---

### User Story 3 - See what's actually being tracked (Priority: P2)

An engineer wants to inspect which git hosts and repo paths are referenced by the workspace
config, to audit or clean it up.

**Why this priority**: Lower-frequency than clone/update/status, but needed to keep the config
itself trustworthy over time.

**Independent Test**: Run the inspect command against a populated config and confirm it lists the
distinct hosts and full set of repo paths.

**Acceptance Scenarios**:

1. **Given** a populated config, **When** the engineer runs the inspect command, **Then** the
   distinct git hosts and repo paths referenced are listed.

### User Story 4 - A quick reference lives right where the repos do (Priority: P2)

An engineer already inside `~/workspaces`, or an AI agent operating there on their behalf, wants
the exact commands for adding a repo, checking status, or authenticating against a private GitLab
instance without leaving that directory or opening a browser.

**Why this priority**: Daily `ws-repos`/`doctor` use is common enough, and specific enough (exact
commands, exact flags), that it deserves a reference next to the repos themselves, not just a
mention on the documentation site.

**Independent Test**: With network access to nothing but the commands themselves, read only
`~/workspaces/README.md` and successfully add a new repo, check its status, and diagnose an
authentication problem, for each of GitHub, GitLab, and a self-hosted GitLab instance.

**Acceptance Scenarios**:

1. **Given** a fresh activation, **When** an engineer opens `~/workspaces/README.md`, **Then** it
   exists and documents `ws-repos`/`doctor` daily use without requiring any other file to be read
   first.
2. **Given** `~/workspaces/README.md`, **When** an engineer wants to clone a private repo from a
   self-hosted GitLab instance (e.g. `gitlab.mycompany.com`), **Then** the file gives the exact
   one-time authentication command and the exact workspace-config entry format for that host.

### Edge Cases

- What happens when two repos in the config reference each other (e.g. via a shared workspace
  file)? The tool must not infinite-loop; each repo path is only ensured once per run.
- What happens when `~/workspaces` doesn't exist yet? It (and an empty config) must be created
  automatically on first shell activation, without ever overwriting an existing config.
- What happens when a repo entry's remote is unreachable? That entry must fail clearly and the
  command must still process the remaining entries rather than aborting the whole run.
- What happens when a `*.mgit.code-workspace` file's `folders` array includes `"path": "."`
  (upstream's convention for "this same repo")? It must be recognized as a self-reference, never
  passed through as a literal path to clone.
- What happens when a `*.mgit.code-workspace` file contains JSON comments (which VS Code itself
  allows there, and upstream's JSONC parser tolerates)? Common comment forms (a whole line
  starting with `//`, a `/* ... */` block) must not break parsing; see FR-008's Assumptions for
  the one blind spot this leaves.
- What happens to `~/workspaces/README.md` on an activation after the first one? It must be
  rewritten every time, unlike the workspace config, since it documents current `ws-repos`/
  `doctor` behavior rather than holding any per-user state of its own; an engineer's local edit to
  it is expected to be overwritten on the next activation, the same as any other home-manager-
  managed file.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A single `ws-repos` command MUST provide `ensure`, `status`, and `inspect`
  subcommands, installed on `PATH` by the base profile (spec 001).
- **FR-002**: `ws-repos ensure` MUST clone a repo listed in the workspace config (default
  `~/workspaces/ws-repos.json`) to its predictable path under `~/workspaces` if absent, or pull it
  if already present, unless that entry is explicitly marked for a fresh reclone.
- **FR-003**: `ws-repos ensure` MUST support repos that reference other repos (e.g. via a
  multi-root workspace file), recursively ensuring each referenced repo, deduplicated per run, and
  MUST treat a `"path": "."` folder entry as a self-reference (skip, never clone) rather than a
  literal path.
- **FR-004**: `ws-repos status` MUST report, per repo: dirty (modified/staged tracked files) and
  untracked files as distinct flags, ahead/behind/no-upstream, and up to date when none of the
  above apply. Each repo's path MUST print relative to the directory `ws-repos status` was invoked
  from, not as an absolute path.
- **FR-004a**: `ws-repos status` MUST additionally report a stuck `index.lock` (as "locked") and a
  non-zero stash count, matching upstream `mgit.ts`'s `mGitStatus()`.
- **FR-004b**: For a repo with an upstream, `ws-repos status` MUST fetch from that upstream before
  computing ahead/behind counts, so a "needs a pull" (behind) result reflects the real remote
  rather than the last time anything happened to fetch it. A fetch failure (e.g. offline) MUST be
  reported as its own distinct state on that repo rather than silently falling back to stale
  ahead/behind numbers or being indistinguishable from up to date.
- **FR-004c**: `ws-repos status` output MUST use one color and one leading icon per repo line
  (clean/up to date, needs a pull, dirty, locked, untracked, ahead, no-upstream, and fetch-failed
  each visually distinct), plus a closing summary line tallying how many repos are up to date, need
  a pull, or need attention. Color MUST auto-disable when stdout is not a terminal, when `NO_COLOR`
  is set (https://no-color.org), or when `TERM=dumb`, matching `doctor`'s own color convention.
- **FR-005**: `ws-repos inspect` MUST list the distinct git hosts and the full set of repo paths
  referenced by the workspace config and any multi-root workspace files it discovers, resolving a
  `"path": "."` entry to the repo the workspace file itself lives in.
- **FR-006**: The base profile MUST create `~/workspaces` and an empty workspace config on first
  activation, without ever overwriting an existing config.
- **FR-006a**: The base profile MUST write `~/workspaces/README.md` on every activation (not just
  the first), covering, at minimum: the `<git-host>/<org>/.../<repo>` directory convention, the
  workspace config format, `ws-repos ensure`/`status`/`inspect`, cloning a public and a private
  repo from GitHub, cloning a public and a private repo from GitLab (including a self-hosted
  instance at a custom hostname), `doctor`/`doctor --all`, a concise reminder of how credentials
  and secrets are handled (spec 002), and a link to the full documentation site (spec 018). It
  MUST describe this repository's own present-day behavior only, with no reference to any earlier
  repository or tool this project's own history includes.
- **FR-007**: The environment health check (spec 004) MUST report whether `ws-repos` is on `PATH`
  and whether `~/workspaces` and its config exist.
- **FR-008**: Parsing a `*.mgit.code-workspace` file MUST tolerate the comment forms VS Code
  itself allows there (a whole-line `//` comment, a `/* ... */` block) rather than requiring
  strict JSON, on a best-effort basis (see Assumptions for the scope boundary this draws, versus
  upstream's full JSONC parser).

### Key Entities

- **Workspace config**: `~/workspaces/ws-repos.json`, the list of repos to manage.
- **Repo entry**: one config entry — at minimum a remote URL and a target path, optionally marked
  for fresh-reclone-only behavior.
- **Workspace README**: `~/workspaces/README.md`, a generated quick reference for `ws-repos` and
  `doctor` daily use, regenerated on every activation, distinct from the workspace config it lives
  beside.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An engineer with an empty `~/workspaces` and a populated config has every listed
  repo cloned to its predictable path after one command.
- **SC-002**: Re-running the ensure command against already-cloned repos never loses uncommitted
  local changes.
- **SC-003**: The status command surfaces every dirty, untracked, locked, or stashed repo under
  `~/workspaces` in one invocation, with no repo silently skipped.
- **SC-004**: `~/workspaces/README.md` exists after every activation and reflects the current
  `ws-repos`/`doctor` behavior, since it is rewritten, not created once and left to drift.
- **SC-005**: A repo whose local knowledge of its upstream is stale (nothing has fetched it
  recently) but which is genuinely behind the real remote is reported as "needs a pull" by
  `ws-repos status`, not "up to date" - verified by resetting a repo's local remote-tracking ref
  backward and confirming `status` still reports it correctly after a real fetch.
- **SC-006**: Running `ws-repos status` with `NO_COLOR=1` set produces output with no ANSI escape
  codes, even when stdout is a terminal.

## Assumptions

- Repos are cloned over the protocol (HTTPS or SSH) the engineer's existing git credentials
  already support; this spec does not add its own auth mechanism.
- The workspace config format is a single JSON file; per-repo config files are out of scope.
- FR-008's comment tolerance is a pragmatic filter (strips whole-line `//` and `/* */` block
  comments), not a full JSONC tokenizer — a `//` or `/*` that happens to appear inside a JSON
  string value (e.g. a URL) is a known, accepted blind spot, the same class of simplification
  `pkgs/pgpass` already documents for its own descriptor format. Reaching for a real parser would
  mean a runtime dependency (e.g. Deno, which upstream uses) this POSIX-shell port deliberately
  does without.
