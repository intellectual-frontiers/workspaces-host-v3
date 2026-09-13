{ pkgs, lib, ... }:

let
  # semtag/git-standup are this flake's own custom-built packages
  # (pkgs/semtag, pkgs/git-standup), not plain nixpkgs attributes, so
  # they're pulled in the same way flake.nix itself does.
  ported = import ../../pkgs { inherit pkgs; };

  # llm (spec 008 FR-005, https://llm.datasette.io/) isn't packaged at the
  # top level of nixpkgs - only as a Python library
  # (python3Packages.llm) - so it needs `toPythonApplication` to get a
  # real `bin/llm`, the same pattern any Python-packaged CLI in nixpkgs
  # needs. `aider-chat` (home/ai-harness.nix) already covers "a
  # provider-agnostic AI CLI that just works" for the base profile, so
  # llm moved here rather than staying a second always-on default.
  llmCli = pkgs.python3Packages.toPythonApplication pkgs.python3Packages.llm;
in
{
  # Agent-ops: operating GitHub-hosted CI/PR workflows, running GitHub
  # Actions locally, bulk multi-repo git tasks, secrets management, and
  # general-purpose scripting - for engineers whose day-to-day is driving
  # AI coding agents and automation against real repositories, rather
  # than a newbie's day-one essentials. `gh`/`specify`/`backlog`/
  # `scaffold-agent-harness`/`git-xargs` are already in the shared base
  # profile (specs 002/008/010/011) - this adds only what's specific to
  # this persona. `git-extras` bundles its own `bin/git-standup`, which
  # collides with this repo's own, already-ported `pkgs/git-standup`;
  # lowPrio makes that one lose the collision rather than failing the
  # build - every other git-extras subcommand is unaffected.
  home.packages = [
    ported.semtag
    ported.git-standup
    (lib.lowPrio pkgs.git-extras)
  ] ++ (with pkgs; [
    act
    gopass
    deno
    llmCli
  ]);
}
