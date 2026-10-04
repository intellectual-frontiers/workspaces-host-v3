{ pkgs, homeConfig
, # Overridable so a second image built from this same definition (spec
  # 027's `oci-image-press`, base + fish + the `press` persona) gets its
  # own internal docker name instead of colliding with the base image's
  # when both are `docker load`ed in the same CI job.
  imageName ? "workspaces-host"
, # The short commit this image is built from (flake.nix's
  # `imageRevision`), written to /etc/os-release as VERSION_ID (spec
  # 031).
  revision ? "unknown"
}:

let
  cfg = homeConfig.config;
  configFile = name: cfg.xdg.configFile.${name}.source;
  # bash's config isn't under xdg.configFile - home-manager writes it as
  # plain dotfiles (~/.bashrc, ~/.bash_profile, ~/.profile),
  # unconditionally, once `programs.bash.enable` is on.
  dotfile = name: cfg.home.file.${name}.source;

  # `dockerTools.buildLayeredImage`'s `contents` merges its list via
  # `symlinkJoin` internally, NOT `pkgs.buildEnv` - a real difference
  # found by actually running the built press image (spec 025), not
  # just building it: `jre_headless`'s own `bin/java` silently vanished
  # from the merged result (no error, no collision message - every
  # other press tool, epubcheck included, still worked, since epubcheck
  # wraps its own JRE dependency independent of PATH) even though a
  # plain `pkgs.buildEnv` over the exact same package list keeps it.
  # Pre-merging with `buildEnv` ourselves and handing `contents` that
  # ONE already-correct environment (plus the image-only extras below,
  # none of which collide with anything in it) sidesteps
  # `symlinkJoin`'s weaker, priority-blind merge entirely.
  mergedPackages = pkgs.buildEnv {
    name = "${imageName}-packages";
    paths = cfg.home.packages;
  };

  # /etc/os-release (spec 031): the devcontainer CLI reads it on `up`
  # (logging "Command in container failed: (cat /etc/os-release || cat
  # /usr/lib/os-release)" without it), and VS Code's server and
  # devcontainer features read it too. This image is no distribution's,
  # so it claims none: no ID_LIKE, which would send a feature script
  # down an apt/apk/dnf path that cannot work here. `flavor` is the
  # image name's suffix ("" for the base image, "press", "rust").
  flavor = pkgs.lib.removePrefix "-" (pkgs.lib.removePrefix "workspaces-host" imageName);
  osRelease = pkgs.writeText "os-release" ''
    ID=workspaces-host
    NAME="Workspaces Host v3"
    VERSION_ID=${revision}
    VERSION="${revision}${pkgs.lib.optionalString (flavor != "") " (${flavor})"}"
    PRETTY_NAME="Workspaces Host v3${pkgs.lib.optionalString (flavor != "") " ${flavor}"} ${revision}"
    VARIANT_ID=${if flavor == "" then "base" else flavor}
    HOME_URL="https://github.com/intellectual-frontiers/workspaces-host-v3"
  '';

  # Generic Linux binaries and wheels (spec 037). The image has no FHS
  # loader and no ld.so.cache, so a manylinux wheel's `driver/node` fails
  # with ENOENT (its ELF interpreter does not exist), and a wheel that
  # dlopens a system library finds none. Two pieces fix that:
  #
  # - nix-ld sits at the loader path generic ELF files name. It starts
  #   NIX_LD (the image's glibc loader) with NIX_LD_LIBRARY_PATH, so such
  #   a binary gets `genericLibs` and nothing else, and no nix-built
  #   program's library choice changes.
  # - LD_LIBRARY_PATH holds the small `dlopenLibs` set. A wheel loaded
  #   into a nix-built interpreter (the image's python, ruby, node) never
  #   passes through nix-ld, so only this variable reaches its dlopen
  #   calls: libstdc++/libgcc_s for greenlet and friends, zlib, and
  #   fribidi/harfbuzz/freetype for Pillow's raqm text layout.
  #
  # The loader path is the one generic binaries of that architecture
  # name.
  isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;
  loaderName = if isAarch64 then "ld-linux-aarch64.so.1" else "ld-linux-x86-64.so.2";
  loaderDir = if isAarch64 then "lib" else "lib64";
  dlopenLibs = with pkgs; [
    stdenv.cc.cc.lib # libstdc++.so.6, libgcc_s.so.1
    zlib
    fribidi
    harfbuzz
    freetype
  ];
  genericLibs = dlopenLibs ++ (with pkgs; [
    zstd
    bzip2
    xz
    openssl
    curl
    expat
    libffi
    glib
    ncurses
    libxml2
    util-linux.lib # libuuid
  ]);
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
  contents = [ mergedPackages ] ++ (with pkgs; [
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

    # A real file at both places the os-release(5) spec names, for the
    # same "path escapes from parent" reason as /etc/passwd above: a
    # symlink into the store would not do (spec 031).
    mkdir -p usr/lib
    cp ${osRelease} etc/os-release
    cp ${osRelease} usr/lib/os-release

    # nix-ld at the loader path generic ELF files name (spec 037). A
    # symlink is fine here: it is resolved by the kernel's exec, which
    # follows it into /nix/store.
    mkdir -p ${loaderDir}
    ln -s ${pkgs.nix-ld}/libexec/nix-ld ${loaderDir}/${loaderName}
  '';

  config = {
    Env = [
      "HOME=/root"
      "USER=root"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "NIX_LD=${pkgs.glibc}/lib/${loaderName}"
      "NIX_LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath genericLibs}"
      "LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath dlopenLibs}"
    ];
    # `-l`: a login shell, guaranteeing the .bash_profile -> .bashrc
    # sourcing chain runs regardless of how the container is invoked.
    Cmd = [ "${pkgs.bashInteractive}/bin/bash" "-l" ];
    WorkingDir = "/root";
  };
}
