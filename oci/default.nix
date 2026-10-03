{ pkgs, homeConfig
, # Overridable so a second image built from this same definition (spec
  # 027's `oci-image-press`, base + fish + the `press` persona) gets its
  # own internal docker name instead of colliding with the base image's
  # when both are `docker load`ed in the same CI job.
  imageName ? "workspaces-host"
}:

let
  cfg = homeConfig.config;
  configFile = name: cfg.xdg.configFile.${name}.source;
  # bash's config isn't under xdg.configFile - home-manager writes it as
  # plain dotfiles (~/.bashrc, ~/.bash_profile, ~/.profile),
  # unconditionally, once `programs.bash.enable` is on.
  dotfile = name: cfg.home.file.${name}.source;
in
pkgs.dockerTools.buildLayeredImage {
  name = imageName;
  tag = "latest";

  # Same closure as the host profile: the exact package set home-manager
  # decided this profile needs (bash, oh-my-posh, direnv, git, ws-repos,
  # doctor, and the core CLI toolset), plus cacert/bash/coreutils for a
  # usable minimal container. gnugrep/gawk close a real gap coreutils
  # doesn't cover: every real host this profile installs onto already
  # has them as part of its base OS, so nothing in home.packages installs
  # them either, but this image has no base OS at all - found by actually
  # running `doctor` inside a built container (spec 021's devcontainer
  # work), which hit bare "grep: command not found"/"awk: command not
  # found" without them.
  #
  # `homeConfig` is base + the `fish` persona (flake.nix's
  # `homeConfigurationsForImage`, spec 022), not bare base - so this one
  # image can back both devcontainer configs (the default bash one and
  # the `-fish` one). `Cmd` below still launches bash: fish is simply
  # also present and configured, ready for a devcontainer config that
  # wants it, the same purely-additive relationship the `fish` persona
  # has to a real host install.
  contents = cfg.home.packages ++ (with pkgs; [
    bashInteractive
    coreutils
    gnugrep
    gawk
    cacert
    dockerTools.fakeNss
    # /usr/bin/env: absent from this image for the same reason
    # gnugrep/gawk were (a dockerTools image starts from nothing, no FHS
    # paths exist unless a package provides them) - found the same way
    # too (spec 023: a downstream repo's own `#!/usr/bin/env bash`/
    # `python3`/`node`-shebanged script failed outright with "cannot
    # execute: required file not found" until this was added).
    dockerTools.usrBinEnv
  ]);

  extraCommands = ''
    mkdir -p root/.config/git root/.config/oh-my-posh root/.config/direnv/lib root/.config/fish/functions root/.nix-profile/etc/profile.d tmp
    cp ${dotfile ".bashrc"} root/.bashrc
    cp ${dotfile ".bash_profile"} root/.bash_profile
    cp ${dotfile ".profile"} root/.profile
    cp ${configFile "git/config"} root/.config/git/config
    cp ${configFile "oh-my-posh/config.json"} root/.config/oh-my-posh/config.json
    cp ${configFile "direnv/lib/hm-nix-direnv.sh"} root/.config/direnv/lib/hm-nix-direnv.sh
    cp ${configFile "fish/config.fish"} root/.config/fish/config.fish
    cp ${configFile "fish/functions/cdp.fish"} root/.config/fish/functions/cdp.fish

    # The copied `.profile` above sources
    # "<home.homeDirectory>/.nix-profile/etc/profile.d/hm-session-vars.sh"
    # literally - home-manager bakes that path in at eval time, assuming
    # its own `switch`-created `~/.nix-profile` symlink farm exists
    # (which this image, with no activation step, never creates). `pkgs,
    # homeConfig` is now evaluated for this image's actual identity
    # (flake.nix's `mkImageHomeConfiguration`: root/"/root", matching
    # `Env`/`WorkingDir` below) specifically so that literal path lines up
    # with where this puts the real file - spec 023's fix for every
    # `home.sessionVariables` entry (PLAYWRIGHT_BROWSERS_PATH included)
    # silently never loading in a login shell. Copied, not symlinked,
    # same reasoning as /etc/passwd below.
    cp ${cfg.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh root/.nix-profile/etc/profile.d/hm-session-vars.sh

    chmod -R u+w root

    # dockerTools.fakeNss (in `contents` above) lands /etc/passwd and
    # /etc/group as symlinks into the Nix store, same as every other
    # package's files in a buildLayeredImage - fine for anything reading
    # them through the ordinary filesystem, but some container tooling
    # resolves paths with its own secure, containment-checking open
    # rather than the kernel's normal symlink-following one (found via
    # the devcontainers CLI's exec shim, spec 021: it refused to read a
    # symlink target under /nix/store, reporting "path escapes from
    # parent"). Materializing them as real, non-symlink files sidesteps
    # that outright.
    rm -f etc/passwd etc/group
    cp ${pkgs.dockerTools.fakeNss}/etc/passwd etc/passwd
    cp ${pkgs.dockerTools.fakeNss}/etc/group etc/group
  '';

  config = {
    Env = [
      "HOME=/root"
      "USER=root"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
    # `-l`: a login shell, guaranteeing the .bash_profile -> .bashrc
    # sourcing chain runs regardless of how the container is invoked.
    Cmd = [ "${pkgs.bashInteractive}/bin/bash" "-l" ];
    WorkingDir = "/root";
  };
}
