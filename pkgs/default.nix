{ pkgs }:

{
  ws-repos = import ./ws-repos { inherit pkgs; };
  ws-persona = import ./ws-persona { inherit pkgs; };
  workspaces-host-update = import ./workspaces-host-update { inherit pkgs; };
  doctor = import ./doctor { inherit pkgs; };
  pgpass = import ./pgpass { inherit pkgs; };
  sensitivectl = import ./sensitivectl { inherit pkgs; };
  semtag = import ./semtag { inherit pkgs; };
  git-standup = import ./git-standup { inherit pkgs; };
  git-xargs = import ./git-xargs { inherit pkgs; };
  specify-cli = import ./specify-cli { inherit pkgs; };
  backlog-md = import ./backlog-md { inherit pkgs; };
  scaffold-agent-harness = import ./scaffold-agent-harness { inherit pkgs; };
  # init-firewall is deliberately NOT included here: it depends on
  # iptables/ipset, which nixpkgs marks unsupported (meta.badPlatforms)
  # on Darwin, and this aggregate feeds every profile's home.packages
  # across all four systems. See flake.nix's Linux-only `packages.<system>`
  # addition and oci/sandboxed.nix, which imports ./init-firewall directly.
}
# surveilr is likewise deliberately conditional rather than unconditional:
# its upstream (surveilr/packages) only publishes x86_64 release binaries
# for Linux and Darwin - no aarch64 asset of either kind exists - so it's
# added here only on the two systems that actually have something to
# fetch (see pkgs/surveilr/default.nix), rather than making `nix flake
# check` fail to evaluate on aarch64-linux/aarch64-darwin the way an
# unconditional `throw` would.
// pkgs.lib.optionalAttrs
  (builtins.elem pkgs.stdenv.hostPlatform.system [ "x86_64-linux" "x86_64-darwin" ])
  { surveilr = import ./surveilr { inherit pkgs; }; }
