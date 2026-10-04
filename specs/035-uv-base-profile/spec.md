# Feature Specification: Keep `uv` in the Base Profile

**Feature Branch**: `035-uv-base-profile`

**Created**: 2026-10-04

**Status**: Implemented

**Input**: User description: "The IF spec `0025-tooling-environment` now has FR-013: a repo's
command line may obtain hash-locked Python packages on first use through `uv`, into uv's own
cache, never into an interpreter the host owns. That relies on `uv` being in the base profile of
every flavor. Please keep it there and have `doctor` check it. If `uv` needs a writable cache
location in the image, set it through `home.sessionVariables`."

## Background

`uv` has been in the base profile since the `data` persona went away (spec 014), in
`home/ai-harness.nix`. Nothing said it had to stay. Now something depends on it, so this makes it
a requirement and has `doctor` check it in the essential output, not only under `--all`.

uv's default cache is `$XDG_CACHE_HOME/uv`, or `~/.cache/uv`, which is already writable in every
image (`HOME=/root`) and on every host. I tested `uv run --with <pkg>` in the image with no
variable set and it worked, so I didn't add `UV_CACHE_DIR`: a variable that restates the default
is one more thing to keep in sync. `doctor` checks the cache directory is writable, and says to
set `UV_CACHE_DIR` if it ever isn't.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The base profile MUST provide `uv` on every system, so every published image has it.
- **FR-002**: `doctor` MUST check `uv` is on PATH in its default output, and FAIL if `uv cache dir`
  is not writable.
- **FR-003**: `uv run --with <package>` MUST work in every published image with no variable set,
  writing only under `$HOME`.

## Success Criteria *(mandatory)*

- **SC-001**: `doctor` in each image passes its `uv` checks.
