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

  # `~/.nix-profile/bin` (every tool this profile installs) has to be on
  # PATH for a plain new shell to find `doctor`/`ws-repos`/anything else
  # here. It's tempting to assume the Nix installer's own `nix.sh`
  # already guarantees this via `~/.profile` - but install.sh's own
  # HOME_MANAGER_BACKUP_EXT step backs up and replaces a pre-existing
  # `~/.profile` (the common case on a brand-new WSL/Debian account,
  # exactly the audience most likely to hit this) with home-manager's
  # own managed one, which doesn't re-source that installer-added line.
  # Declaring it here means `hm-session-vars.sh` sets PATH itself,
  # independent of whatever the raw Nix installer did or didn't leave
  # behind - see home/shell.nix for the second half of this fix (sourcing
  # it from `.bashrc` too, not just `.profile`).
  home.sessionPath = [ "$HOME/.nix-profile/bin" ];

  # A fresh Debian/WSL image commonly has `LANG=en_US.UTF-8` configured
  # as the OS default without that locale actually being generated,
  # which prints a `setlocale: cannot change locale` warning on every
  # single shell startup - install.sh fixes the OS-level default on
  # Debian/Ubuntu directly, but this is a second, tool-independent
  # backstop: C.UTF-8 is a special locale glibc always has built in, no
  # `locale-gen` required, so this is correct everywhere this profile
  # runs, not just WSL.
  home.sessionVariables = {
    LANG = "C.UTF-8";
    LC_ALL = "C.UTF-8";
  };
}
