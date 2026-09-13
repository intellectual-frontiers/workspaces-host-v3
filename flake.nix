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
  };

  outputs = { self, nixpkgs, home-manager }:
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
      };

      # Per-persona profiles (spec 014): each adds a small, focused package
      # set on top of the shared base (home/) - composable slices rather
      # than one global package list.
      personaModules = {
        backend = ./home/profiles/backend.nix;
        data = ./home/profiles/data.nix;
        mobile = ./home/profiles/mobile.nix;
        agent-ops = ./home/profiles/agent-ops.nix;
        compliance = ./home/profiles/compliance.nix;
        networking = ./home/profiles/networking.nix;
        fish = ./home/profiles/fish.nix;
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
            homeConfig = homeConfigurationsFor.${system};
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
