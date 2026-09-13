{ ... }:

{
  imports = [
    ./shell.nix
    ./direnv.nix
    ./git.nix
    ./tools.nix
    ./secrets.nix
    ./workspaces.nix
  ];

  # home.username, home.homeDirectory, and home.stateVersion are supplied by
  # the caller (see flake.nix's mkHomeConfiguration) so this module set stays
  # reusable across the `default`/per-system/`current` profiles.

  home.enableNixpkgsReleaseCheck = false;

  programs.home-manager.enable = true;
}
