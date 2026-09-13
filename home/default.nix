{ ... }:

let
  # The one supported place for personal, machine-specific Nix-level
  # overrides (git identity, real `workspacesHost.secrets` declarations,
  # extra packages) - see local.nix.example at the repo root and spec
  # 013. Deliberately OUTSIDE this repo's own directory (not just
  # .gitignore'd inside it): a flake evaluated from a git checkout only
  # ever sees git-tracked files, even with `--impure` and even for a
  # file that's merely gitignored-but-present on disk, so a local
  # override file has to live somewhere Nix reads directly off the
  # filesystem instead - only possible impurely, which is why this
  # silently does nothing (no error) under `nix flake check`'s pure
  # evaluation: `default` and every per-system profile just don't have
  # one; only `current` (flake.nix's impure, real-identity profile)
  # actually picks it up. `/. + string` coerces the dynamically-computed
  # string into an actual Nix path value - a bare string in `imports`
  # confuses the module system.
  localConfigPath = /. + (builtins.getEnv "HOME" + "/.config/workspaces-host/local.nix");
in
{
  imports = [
    ./shell.nix
    ./direnv.nix
    ./git.nix
    ./tools.nix
    ./secrets.nix
    ./workspaces.nix
    ./ai-harness.nix
    ./fonts.nix
  ] ++ (if builtins.pathExists localConfigPath then [ localConfigPath ] else [ ]);

  # home.username, home.homeDirectory, and home.stateVersion are supplied by
  # the caller (see flake.nix's mkHomeConfiguration) so this module set stays
  # reusable across the `default`/per-system/`current` profiles.

  home.enableNixpkgsReleaseCheck = false;

  programs.home-manager.enable = true;
}
