{ pkgs, ... }:

{
  # Agent-ops: operating GitHub-hosted CI/PR workflows and running GitHub
  # Actions locally, for engineers whose day-to-day is driving AI coding
  # agents against real repositories rather than writing application code
  # directly. `gh`/`specify`/`backlog`/`scaffold-agent-harness` are
  # already in the shared base profile (specs 002/008/010) - this adds
  # only what's specific to this persona.
  home.packages = with pkgs; [
    act
  ];
}
