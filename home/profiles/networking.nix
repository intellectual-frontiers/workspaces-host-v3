{ pkgs, ... }:

{
  # Zero-trust networking clients (spec 017) - Tailscale/Nebula. Clients
  # only: no service module, no auto-start, no key material - joining a
  # tailnet/mesh is always an explicit, engineer-initiated action (see
  # README). Moved out of the base profile in a newbie-simplification
  # pass: most engineers never touch a VPN client on day one, and until
  # they do, this is one fewer thing for `doctor` to mention.
  home.packages = with pkgs; [
    tailscale
    nebula
  ];
}
