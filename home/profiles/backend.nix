{ pkgs, ... }:

let
  # pgpass is this flake's own custom-built package (pkgs/pgpass), not a
  # plain nixpkgs attribute, so it's pulled in the same way flake.nix
  # itself does. home/postgres.nix (imported below) only manages the
  # ~/.pgpass/~/.psqlrc *files* - the CLI tool that reads them has to be
  # added to home.packages separately, same as every other ported tool.
  ported = import ../../pkgs { inherit pkgs; };
in
{
  # Backend/service development: DB/cache clients, a compose-based
  # local-stack runner, and the Java + Postgres toolchain (spec 007) -
  # importing the same shared home/java.nix and home/postgres.nix
  # modules the base profile used to pull in unconditionally. Moved here
  # in a newbie-simplification pass: a JDK/Maven and a bootstrapped
  # ~/.pgpass are only relevant to backend/JVM/DB work, not every
  # engineer's day one.
  imports = [
    ../java.nix
    ../postgres.nix
  ];

  home.packages = [ ported.pgpass ] ++ (with pkgs; [
    postgresql
    redis
    docker-compose
    httpie
  ]);
}
