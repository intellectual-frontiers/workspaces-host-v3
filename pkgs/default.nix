{ pkgs }:

{
  mgit = import ./mgit { inherit pkgs; };
  workspaces-host-update = import ./workspaces-host-update { inherit pkgs; };
  doctor = import ./doctor { inherit pkgs; };
  # init-firewall is deliberately NOT included here: it depends on
  # iptables/ipset, which nixpkgs marks unsupported (meta.badPlatforms)
  # on Darwin, and this aggregate feeds every profile's home.packages
  # across all four systems. See flake.nix's Linux-only `packages.<system>`
  # addition and oci/sandboxed.nix, which imports ./init-firewall directly.
}
