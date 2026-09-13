# Feature Specification: Compliance & Observability Tooling

**Feature Branch**: `006-compliance-observability`

**Created**: 2026-09-13

**Status**: Implemented

**Input**: User description: "Compliance and observability tooling (osquery, cnquery, steampipe,
OpenObserve, surveilr) to audit the sandbox itself"

## Background

A newbie-simplification audit (see spec 014's own follow-up) found this tooling was the single
largest contributor to a freshly-installed engineer's `doctor` output, despite having zero payoff
for anyone not doing compliance/audit work. It now ships behind the `compliance` persona (spec
014) instead of the base profile — activating it still gets all five tools with nothing extra to
opt into; not activating it means a new engineer's first `doctor` run doesn't mention any of them.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Audit the sandbox itself (Priority: P1)

An engineer or a security reviewer wants to query the running sandbox's own state (installed
packages, open ports, running processes, filesystem posture) using standard compliance-as-code
tooling, without installing anything themselves.

**Why this priority**: A reproducible environment is only trustworthy if it can also prove its own
state; this closes the loop with spec 004's health check by giving deeper, queryable introspection.

**Independent Test**: On an activated profile, run one of the bundled tools' standard queries
against the local system and confirm it returns real results.

**Acceptance Scenarios**:

1. **Given** an activated profile on Linux, **When** the engineer runs the bundled query tool,
   **Then** it returns real data about the running system with no separate install step.

### Edge Cases

- What happens on a platform where one of these tools has no published build (e.g. `osquery` on
  some non-Linux targets, or `surveilr` on some architectures)? Its absence must be an
  informational WARN from `doctor`, not a FAIL, and must not block installing the rest.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `compliance` persona (spec 014) MUST install `cnquery`, `steampipe`, and
  `openobserve` on every supported system.
- **FR-002**: The `compliance` persona MUST install `osquery` on Linux systems.
- **FR-003**: The `compliance` persona MUST install `surveilr` on the systems it publishes a
  release asset for.
- **FR-004**: The environment health check (spec 004) MUST report each of these five tools as an
  informational WARN (not a FAIL) when absent — whether because the persona isn't active or
  because the platform doesn't support that tool — and as PASS when present.
- **FR-005**: Documentation MUST explain what each tool is for and any platform caveats.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All five tools (where the platform supports them) are usable immediately after
  activation with no manual install step.

## Assumptions

- This spec provisions the tools themselves; it does not define specific compliance policies or
  queries to run with them — that remains project-specific and out of scope here.
