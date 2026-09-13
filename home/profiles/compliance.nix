{ pkgs, lib, ... }:

let
  # cnquery (compliance/observability, spec 006) fetches its source with
  # fetchFromGitHub, a sandboxed fixed-output derivation build whose own
  # curl can't TLS-validate an egress proxy the way the outer `nix` CLI
  # process can. builtins.fetchGit, evaluated by that outer process,
  # sidesteps it the same way; vendorHash is untouched since the fetched
  # tree is byte-identical to the tagged release archive.
  cnquery' = pkgs.cnquery.overrideAttrs (_old: {
    src = builtins.fetchGit {
      url = "https://github.com/mondoohq/cnquery";
      rev = "7dee6bd537cb4a04c223a19394726fa8707171e6"; # v11.19.1
    };
  });

  # surveilr is this flake's own custom-built package (pkgs/surveilr),
  # not a plain nixpkgs attribute, so it's pulled in the same way
  # flake.nix itself does.
  ported = import ../../pkgs { inherit pkgs; };
in
{
  # Compliance/observability tooling (spec 006) - auditing the sandbox
  # itself (SOC2 and similar requirements), or just understanding what's
  # actually running on the machine. Moved out of the base profile in a
  # newbie-simplification pass: real value only for a security/compliance
  # use case, not every engineer's first day, and it was previously the
  # single biggest contributor to `doctor`'s default output.
  home.packages = (with pkgs; [
    steampipe
    openobserve
    cnquery'
  ])
  # osquery is nixpkgs-packaged Linux-only (meta.platforms = platforms.linux).
  ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.osquery
  # surveilr's upstream only publishes x86_64 release binaries for Linux
  # and Darwin - the same guard pkgs/default.nix uses.
  ++ lib.optional
    (builtins.elem pkgs.stdenv.hostPlatform.system [ "x86_64-linux" "x86_64-darwin" ])
    ported.surveilr;
}
