{
  description = "Workspaces Host v3 - core flake: home-manager module (bash, oh-my-posh, direnv, git), mgit workspace management, doctor health check, and an OCI image built from the same closure";

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-24.11&shallow=1";

    home-manager = {
      url = "git+https://github.com/nix-community/home-manager?ref=release-24.11&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      # Manual per-system iteration rather than a flake-utils dependency:
      # keeps this flake's own input set minimal.
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      # cnquery (home/tools.nix, compliance/observability tooling, spec
      # 006) is the only unfree package this flake pulls in (nixpkgs
      # marks it `bsl11`) - allowed by name rather than a blanket
      # `allowUnfreePredicate = true` so a future unfree package doesn't
      # slip in unnoticed.
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
      homeConfigurations = homeConfigurationsFor // personaConfigurations // currentPersonaConfigurations // {
        default = homeConfigurationsFor.x86_64-linux;
        current = mkCurrentUserHomeConfiguration [ ];
      };

      checks = forAllSystems (system: {
        default = homeConfigurationsFor.${system}.activationPackage;
      });
    };
}
