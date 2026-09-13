# Skills directory convention

Project-local skills live here, under `.claude/skills/<skill-name>/SKILL.md`,
and are committed to the repo - they're part of this project's own
conventions (build steps, review checklists, repo-specific workflows), not
personal preferences.

Personal/global skills that should apply across every project (not just
this one) belong in `~/.claude/skills/` on the engineer's own machine
instead - Claude Code checks both locations, and a project-local skill of
the same name takes precedence over a global one.

This directory starts empty in the template; `specify` (packaged by this
flake, see `pkgs/specify-cli`) populates `speckit-*` skills here once you
run `specify init` for spec-driven development on a new feature.
