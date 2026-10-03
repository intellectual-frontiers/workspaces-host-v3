# Feature Specification: Media Persona

**Feature Branch**: `026-media-persona`

**Created**: 2026-10-03

**Status**: Implemented

**Input**: User description: "A `media` persona: faster-whisper (Python) plus anything it needs
at runtime (e.g. ffmpeg). Keep it out of the base profile; it is heavy."

## Background

`faster-whisper` (a CTranslate2-based reimplementation of OpenAI Whisper for local speech-to-text)
is another document/data-adjacent tool an Intellectual Frontiers repo currently installs via pip -
but unlike spec 024's base-profile additions, its own dependency closure pulls in CTranslate2,
ONNX Runtime, and OpenBLAS, each large and CPU-architecture-specific. That's real weight every
engineer would pay on every rebuild if it lived in the base profile, for a capability (local audio
transcription) only some repos need - exactly the judgment call that already separates, say,
`compliance`'s osquery/cnquery/steampipe from the base profile. A new, narrowly-scoped persona
mirrors that pattern instead of growing an existing one, since transcription has nothing to do with
any current persona's own focus (backend, mobile, agent-ops, compliance, networking, fish).

`ffmpeg` is `faster-whisper`'s real runtime dependency: it decodes whatever audio/video container
format a file actually arrives in before CTranslate2 ever sees raw PCM samples - without it on
PATH, `faster-whisper` fails the moment it's given anything other than a pre-decoded WAV.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Local transcription, no setup step (Priority: P3)

An engineer or AI agent working in a repo that needs local audio transcription activates the
`media` persona once, then runs that repo's own `faster-whisper`-based script with no further
install step.

**Why this priority**: Narrower audience than spec 024's base-profile additions - genuinely opt-in,
the same tier as `compliance`/`networking` rather than something every engineer needs on day one.

**Independent Test**: With the `media` persona activated, `python3 -c 'import faster_whisper'`
succeeds and `ffmpeg -version` runs.

**Acceptance Scenarios**:

1. **Given** no persona activated, **When** `doctor --all` runs, **Then** `faster_whisper`/`ffmpeg`
   report as optional, pointing at `ws-persona activate media`, not a FAIL.
2. **Given** the `media` persona activated and `workspaces-host-update` run, **When** the import/
   version checks above run, **Then** both succeed.

### Edge Cases

- This persona is deliberately NOT included in either published OCI image (spec 027): it's heavy
  enough (CTranslate2/ONNX Runtime/OpenBLAS) that baking it into every pull of the base or press
  image would cost everyone the download for a capability only some repos need - a real host or VM
  install activates it with `ws-persona activate media` instead, same as every other persona not
  baked into an image.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A new `media` persona (`home/profiles/media.nix`) MUST provide the `faster-whisper`
  Python package and `ffmpeg`, registered in `flake.nix`'s `personaModules` and `pkgs/ws-persona`'s
  persona table.
- **FR-002**: `doctor --all` MUST report `faster_whisper`/`ffmpeg` as optional (pointing at
  `ws-persona activate media`) when the persona isn't active, and PASS when it is.
- **FR-003**: `media` MUST NOT be added to either published OCI image (spec 020/027) - activated
  only on a real host/VM install, per the Background's weight rationale.
- **FR-004**: The documentation book's personas chapter MUST document `media`, consistent with
  every other persona's entry there.

### Key Entities

- **`home/profiles/media.nix`**: the new persona module.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `ws-persona activate media && workspaces-host-update` makes `import faster_whisper`
  and `ffmpeg -version` both succeed.
- **SC-002**: No persona activated keeps `python3 -c 'import faster_whisper'` failing (proving it's
  genuinely opt-in, not silently always present).

## Assumptions

- `faster-whisper`'s own Python package name (`faster_whisper`, underscore) differs from its PyPI/
  persona name (`faster-whisper`, hyphen) - ordinary Python packaging convention, not a typo.
