{ pkgs, ... }:

{
  # Data engineering/analysis: a Python toolchain and a local analytical
  # database, on top of the shared base profile. `uv` and `duckdb` trace
  # back to workspaces-host-v1's own Homebrew package list (spec 014).
  home.packages = with pkgs; [
    python3
    uv
    duckdb
  ];
}
