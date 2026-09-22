{ pkgs, lib, ... }:

let
  # cnquery (compliance/observability, spec 006) fetches its source with
  # fetchFromGitHub, a sandboxed fixed-output derivation build whose own
  # curl can't TLS-validate an egress proxy the way the outer `nix` CLI
  # process can. builtins.fetchGit, evaluated by that outer process,
  # sidesteps it the same way.
  #
  # vendorHash MUST be pinned explicitly here too, not inherited from
  # nixpkgs.cnquery's own default (issue #2): buildGoModule's internal
  # go-modules fixed-output derivation depends on both `src` and
  # `vendorHash` together (nixpkgs/pkgs/build-support/go/module.nix
  # threads both through its `finalAttrs` self-reference), so
  # overriding `src` alone still checks the rebuilt go-modules output
  # against whatever `vendorHash` nixpkgs currently pins for its own,
  # different cnquery version - byte-identical only as long as
  # nixpkgs.cnquery happens to sit on the exact same release this flake
  # pins, and silently wrong the moment nixpkgs bumps it, exactly as
  # happened here (nixpkgs moved to v11.53.2's vendorHash while this
  # rev stayed on v11.19.1). The value below is v11.19.1's own,
  # independently pinned go-modules hash - correct regardless of
  # whatever version nixpkgs.cnquery is on.
  cnquery' = pkgs.cnquery.overrideAttrs (_old: {
    src = builtins.fetchGit {
      url = "https://github.com/mondoohq/cnquery";
      rev = "7dee6bd537cb4a04c223a19394726fa8707171e6"; # v11.19.1
    };
    vendorHash = "sha256-mS+79EvNCQJeE90WZDLvj2akMWtarVAolAralZHsZuU=";
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
