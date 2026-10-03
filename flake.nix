{
  description = "Workspaces Host v3 - core flake: home-manager module (bash, oh-my-posh, direnv, git), ws-repos workspace management, doctor health check, and an OCI image built from the same closure";

  inputs = {
    # Bumped from nixos-24.11 specifically to get fish 4.x (spec 014's
    # `fish` persona needs the Rust rewrite, not the 3.7 C++ line
    # nixos-24.11 stays on for its whole release lifetime - stable
    # branches don't backport a shell's major rewrite).
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-25.05&shallow=1";

    home-manager = {
      url = "git+https://github.com/nix-community/home-manager?ref=release-25.05&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The `rust` persona's one exception to "nixpkgs' own packages, no
    # second toolchain source" (addendum to spec 029): this flake's
    # pinned nixpkgs revision ships rustc 1.86.0, which clears the
    # >=1.85 edition-2024 floor in the abstract, but
    # `www.intellectualfrontiers.com`'s own, real `Cargo.lock` pins
    # `oxrdf`/`oxttl` versions that need rustc 1.87 - confirmed directly
    # by actually running `cargo test --locked` against that repo's
    # checkout, not assumed from its `rust-version` field alone. Rather
    # than bumping this whole flake's nixpkgs pin (every other package
    # this flake provides would move with it) for one persona's
    # toolchain, `rust-overlay` provides prebuilt, individually
    # versioned rustc releases - `inputs.nixpkgs.follows` keeps it from
    # pulling in a second nixpkgs copy, and `flake.lock` pins its own
    # revision exactly like every other input here (not rustup, which
    # manages toolchains entirely outside Nix - Constitution Principle
    # I). `git+https`, not `github:`, matches this flake's own existing
    # input style for `nixpkgs`/`home-manager` above.
    rust-overlay = {
      url = "git+https://github.com/oxalica/rust-overlay?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, rust-overlay }:
    let
      # Manual per-system iteration rather than a flake-utils dependency:
      # keeps this flake's own input set minimal.
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      # cnquery (home/profiles/compliance.nix, spec 006) is the only
      # unfree package this flake pulls in (nixpkgs marks it `bsl11`) -
      # allowed by name rather than a blanket `allowUnfreePredicate =
      # true` so a future unfree package doesn't slip in unnoticed.
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "cnquery" ];
        overlays = [ rust-overlay.overlays.default ];
      };

      # Per-persona profiles (spec 014): each adds a small, focused package
      # set on top of the shared base (home/) - composable slices rather
      # than one global package list.
      personaModules = {
        backend = ./home/profiles/backend.nix;
        mobile = ./home/profiles/mobile.nix;
        agent-ops = ./home/profiles/agent-ops.nix;
        compliance = ./home/profiles/compliance.nix;
        networking = ./home/profiles/networking.nix;
        fish = ./home/profiles/fish.nix;
        press = ./home/profiles/press.nix;
        media = ./home/profiles/media.nix;
        rust = ./home/profiles/rust.nix;
      };

      mkHomeConfiguration = system: extraModules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          modules = [
            ./home
          ] ++ extraModules ++ [
            {
              # Fixed test identity, deliberately NOT "the real you" - this
              # is what `nix flake check`/CI builds against, so it has to
              # be pure (no reading the environment). Real installs use
              # `homeConfigurations.current` below instead, which picks up
              # your actual username/home directory.
              home.username = "workspace";
              home.homeDirectory =
                if nixpkgs.lib.hasSuffix "darwin" system
                then "/Users/workspace"
                else "/home/workspace";
              home.stateVersion = "24.11";
            }
          ];
        };

      # Computed once per system so `packages`, `homeConfigurations`, and
      # `checks` all build the OCI image and the activation package from
      # the exact same evaluated home-manager config (Constitution
      # Principle IV: host and container share one closure).
      homeConfigurationsFor = forAllSystems (system: mkHomeConfiguration system [ ]);

      # A dedicated identity for `packages.<system>.oci-image*` below,
      # distinct from `mkHomeConfiguration`'s fixed "workspace"/
      # "/home/workspace" test identity: the image's own `Env`/`WorkingDir`
      # (oci/default.nix) run as root with `HOME=/root`, and home-manager
      # bakes `home.homeDirectory` literally into generated content it
      # assumes its own activation will place under exactly that path
      # (bash's `.profile` sourcing `<homeDirectory>/.nix-profile/etc/
      # profile.d/hm-session-vars.sh`, `WORKSPACES_HOST_REPO`, ...) - spec
      # 023 found this mismatch (evaluated for `/home/workspace`, run as
      # `/root`) is exactly why every `home.sessionVariables` entry
      # (PLAYWRIGHT_BROWSERS_PATH included) was silently unset in the
      # image: `.profile` was sourcing a path that could never exist.
      # Evaluating for the identity the image actually runs as fixes that
      # at the root, not just the one path.
      mkImageHomeConfiguration = system: extraModules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          modules = [
            ./home
          ] ++ extraModules ++ [
            {
              home.username = "root";
              home.homeDirectory = "/root";
              home.stateVersion = "24.11";
            }
          ];
        };

      # The published OCI image (`packages.<system>.oci-image` below) is
      # built from base + the `fish` persona rather than bare
      # `homeConfigurationsFor`, so the one published image can back both
      # devcontainer configs (spec 021/022): the default one (bash, as
      # every other profile has it) and the `-fish` one, which only
      # switches the devcontainer's own default shell - personas are
      # purely additive, so nothing about the bash experience changes
      # for anyone who doesn't ask for fish. This needs every system
      # `oci-image` itself does (unlike `personaConfigurations` below,
      # deliberately pinned to one system for interactive persona
      # testing), so it's its own `forAllSystems`, not a reuse of that
      # x86_64-linux-only attribute.
      homeConfigurationsForImage = forAllSystems (system: mkImageHomeConfiguration system [ ./home/profiles/fish.nix ]);

      # spec 027's second published image: base + fish + the `press`
      # persona (book/paper typesetting), so an IF repo that needs
      # AsciiDoc/LaTeX/EPUB tooling can pull a purpose-built image instead
      # of installing press's (large) closure into every container.
      homeConfigurationsForPressImage = forAllSystems (system: mkImageHomeConfiguration system [ ./home/profiles/fish.nix ./home/profiles/press.nix ]);

      # A third published image (addendum to spec 029): base + fish +
      # the `rust` persona (a stable Rust toolchain plus the native
      # build toolchain its heaviest dependency graphs need), for an IF
      # repository whose own stack is Rust - same reasoning as
      # `homeConfigurationsForPressImage` above (ship the heavy, opt-in
      # persona as its own image rather than growing the base one every
      # repo pulls regardless of language).
      homeConfigurationsForRustImage = forAllSystems (system: mkImageHomeConfiguration system [ ./home/profiles/fish.nix ./home/profiles/rust.nix ]);

      # Persona configurations are pinned to x86_64-linux, same rationale
      # as `default` below: engineers on another platform substitute that
      # system's own attribute (or fork a persona module for their
      # platform) rather than this flake enumerating every
      # persona x system combination up front.
      personaConfigurations = nixpkgs.lib.mapAttrs
        (_name: modulePath: mkHomeConfiguration "x86_64-linux" [ modulePath ])
        personaModules;

      # Where `ws-persona activate <name>` records which personas
      # `current` should combine, so a choice made once keeps applying
      # on every future `workspaces-host-update` instead of needing
      # `WORKSPACES_HOST_PROFILE` re-specified by hand each time (spec
      # 014's "combine and persist personas" follow-up). Same rationale
      # as `home/default.nix`'s `localConfigPath`: only `current` reads
      # this, and only impurely, so `nix flake check`'s pure evaluation
      # never sees it.
      personasStatePath = /. + (builtins.getEnv "HOME" + "/.config/workspaces-host/personas");

      # One persona name per line; "#" starts a comment (inline or
      # whole-line) and blank lines are ignored - the same tolerant,
      # hand-editable-and-forgiving parsing style
      # `workspaces-host-update` already uses for the credentials file.
      # An unrecognized name is dropped with a `builtins.trace` warning
      # rather than a hard eval error, so one typo can't break every
      # future `current` build.
      activePersonaModules =
        if builtins.pathExists personasStatePath then
          let
            names = nixpkgs.lib.unique (builtins.filter (n: n != "") (map
              (line: nixpkgs.lib.trim (builtins.elemAt (nixpkgs.lib.splitString "#" line) 0))
              (nixpkgs.lib.splitString "\n" (builtins.readFile personasStatePath))));
          in
          builtins.concatMap
            (name:
              if builtins.hasAttr name personaModules then
                [ personaModules.${name} ]
              else
                builtins.trace
                  "workspaces-host: ~/.config/workspaces-host/personas names an unknown persona '${name}' - ignoring it (see `ws-persona list` for valid names)"
                  [ ])
            names
        else
          [ ];

      # The identity real installs actually use: `builtins.getEnv`/
      # `builtins.currentSystem` read whoever is actually running the
      # build, instead of the fixed "workspace" identity `default` uses.
      # This needs `--impure`; `nix flake check` never touches it, so CI
      # stays fully pure.
      mkCurrentUserHomeConfiguration = extraModules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor builtins.currentSystem;
          modules = [
            ./home
          ] ++ extraModules ++ [
            {
              home.username = builtins.getEnv "USER";
              home.homeDirectory = builtins.getEnv "HOME";
              home.stateVersion = "24.11";
            }
          ];
        };

      # One "current-<persona>" per persona module, same relationship
      # `current` has to `default`: the real-identity counterpart to
      # `personaConfigurations` above, so a persona profile also works
      # for whoever is actually running it, not just an engineer whose
      # real username happens to be "workspace".
      currentPersonaConfigurations = nixpkgs.lib.mapAttrs'
        (name: modulePath: {
          name = "current-${name}";
          value = mkCurrentUserHomeConfiguration [ modulePath ];
        })
        personaModules;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          ported = import ./pkgs { inherit pkgs; };
        in
        ported // {
          oci-image = import ./oci {
            inherit pkgs;
            homeConfig = homeConfigurationsForImage.${system};
          };
          oci-image-press = import ./oci {
            inherit pkgs;
            homeConfig = homeConfigurationsForPressImage.${system};
            imageName = "workspaces-host-press";
          };
          oci-image-rust = import ./oci {
            inherit pkgs;
            homeConfig = homeConfigurationsForRustImage.${system};
            imageName = "workspaces-host-rust";
          };
        }
        # init-firewall (iptables/ipset) declares itself unsupported on
        # Darwin at the nixpkgs level (meta.badPlatforms), which fails
        # *evaluation*, not just building - so this pair can only be
        # listed as a package attribute on Linux.
        // nixpkgs.lib.optionalAttrs (nixpkgs.lib.hasSuffix "linux" system) {
          init-firewall = import ./pkgs/init-firewall { inherit pkgs; };
          oci-image-sandboxed = import ./oci/sandboxed.nix {
            inherit pkgs;
            homeConfig = homeConfigurationsFor.${system};
          };
        }
      );

      # One home-manager profile per supported system, so `nix flake check`
      # and CI can build every platform, using the fixed "workspace" test
      # identity. Real installs (see README's Installation section) use
      # `current` instead, which needs `--impure` but picks up whoever is
      # actually running the build.
      #
      # `current` builds with every persona `ws-persona activate` has
      # recorded (`activePersonaModules`, empty for anyone who has never
      # activated one) - this is what makes personas actually combine
      # (backend and fish and anything else, together) and persist
      # across every future `workspaces-host-update` with no
      # `WORKSPACES_HOST_PROFILE` needed. `current-<persona>` below
      # stays a single-persona, non-persisting build for trying one
      # persona in isolation without touching your activated list.
      homeConfigurations = homeConfigurationsFor // personaConfigurations // currentPersonaConfigurations // {
        default = homeConfigurationsFor.x86_64-linux;
        current = mkCurrentUserHomeConfiguration activePersonaModules;
      };

      checks = forAllSystems (system: {
        default = homeConfigurationsFor.${system}.activationPackage;
      });
    };
}
