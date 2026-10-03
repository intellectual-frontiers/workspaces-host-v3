{ pkgs, ... }:

{
  # Data engineering/analysis on top of the shared base profile, which
  # already provisions python3/uv unconditionally (home/ai-harness.nix -
  # most MCP servers an AI agent reaches for are uvx-launched Python
  # packages, so that pair moved out of this persona and into every
  # profile). `duckdb`, a local analytical database, is what's left here
  # - it traces back to workspaces-host-v1's own Homebrew package list
  # (spec 014), same as `uv` originally did.
  home.packages = with pkgs; [
    duckdb
  ];
}
