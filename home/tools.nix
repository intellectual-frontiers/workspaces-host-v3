{ pkgs, ... }:

let
  # ws-repos, doctor, workspaces-host-update, pgpass, sensitivectl, semtag,
  # git-standup, git-xargs, specify-cli, backlog-md, scaffold-agent-harness
  # (pkgs/default.nix) - built as flake packages, but only actually land
  # on PATH once they're also listed in home.packages like every other
  # tool here.
  ported = import ../pkgs { inherit pkgs; };

  # cnquery (compliance/observability, spec 006) fetches its source with
  # fetchFromGitHub, a sandboxed fixed-output derivation build whose own
  # curl can't TLS-validate an egress proxy the way the outer `nix` CLI
  # process can (the same class of problem pkgs/specify-cli documents).
  # builtins.fetchGit, evaluated by that outer process, sidesteps it the
  # same way; vendorHash is untouched since the fetched tree is
  # byte-identical to the tagged release archive.
  cnquery' = pkgs.cnquery.overrideAttrs (_old: {
    src = builtins.fetchGit {
      url = "https://github.com/mondoohq/cnquery";
      rev = "7dee6bd537cb4a04c223a19394726fa8707171e6"; # v11.19.1
    };
  });
in
{
  home.packages = (builtins.attrValues ported) ++ (with pkgs; [
    # Everyday CLI tools (spec 001 FR-007). `ripgrep`/`fd` back fzf's
    # file/dir widgets (home/shell.nix), `jq`/`findutils` back `ws-repos`
    # (pkgs/ws-repos), `eza`/`bat` are the aliased `ls`/`cat` replacements
    # (home/shell.nix), and `blesh` is bash's syntax-highlighting/
    # autosuggestion engine sourced directly by store path there - listed
    # here too so its own helper commands are on PATH for manual use.
    ripgrep
    fd
    jq
    bat
    eza
    blesh
    # Scans a repo for anything that looks like a committed secret -
    # `gitleaks detect --source . -v` - the practical backstop for
    # "keeping credentials out of git history" (README) alongside a
    # project's own .gitignore and reviewing `git diff --staged`.
    gitleaks

    # Compliance & observability tooling (spec 006) - plain nixpkgs
    # packages, so they flow in here directly rather than through
    # pkgs/default.nix's aggregate of this repo's own custom-built tools.
    steampipe
    openobserve

    # Bulk multi-repo git tooling (spec 011) - a plain nixpkgs package,
    # so it flows in here directly. git-extras bundles its own
    # `bin/git-standup`, which collides with this repo's own, already-
    # ported `pkgs/git-standup`; lowPrio makes that one lose the
    # collision rather than failing the build - every other git-extras
    # subcommand is unaffected.
    (lib.lowPrio git-extras)

    # Additional ported utilities (spec 015) - small, general-purpose
    # tools a v1-vs-v2-vs-v3 parity audit found missing: general secrets
    # management, a plain HTTP fetcher, a directly-runnable `rclone`
    # (previously only vendored inside pkgs/sensitivectl's own wrapped
    # PATH), changelog generation, and the Deno runtime v1 called "a core
    # requirement" (this repo's own tooling no longer needs it - ws-repos/
    # doctor are POSIX sh - but that's a separate question from whether
    # engineers should have it available, per spec 015's background).
    gopass
    wget
    rclone
    git-chglog
    deno

    # Lefthook git hooks manager (spec 016) - fulfills a v1 roadmap item
    # that v1 itself never built. See templates/lefthook.yml.example.
    lefthook

    # Zero-trust networking clients (spec 017) - fulfills another v1
    # roadmap item v1 never built. Clients only: no service module, no
    # auto-start, no key material - joining a tailnet/mesh is always an
    # explicit, engineer-initiated action (README documents the steps).
    tailscale
    nebula
  ] ++ [ cnquery' ])
  # osquery is nixpkgs-packaged Linux-only (meta.platforms = platforms.linux
  # at pkgs/tools/system/osquery) - unlike cnquery/steampipe/openobserve
  # above, referencing it unconditionally would fail to evaluate
  # home.packages on Darwin, so it's added only where it actually builds.
  ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.osquery;
}
