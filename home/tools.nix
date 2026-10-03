{ config, lib, pkgs, ... }:

let
  # ws-repos, ws-persona, doctor, workspaces-host-update, sensitivectl, specify-cli,
  # backlog-md, scaffold-agent-harness, git-xargs (pkgs/default.nix) -
  # built as flake packages, but only actually land on PATH once they're
  # also listed in home.packages like every other tool here. Persona-
  # specific ported tools (pgpass -> backend, surveilr -> compliance,
  # semtag/git-standup -> agent-ops) are added by their own persona
  # module instead of here (a newbie-simplification pass), so activating
  # no persona keeps this list to what every profile actually needs.
  ported = import ../pkgs { inherit pkgs; };

  # The base profile's document/data toolchain (spec 024): RDF graph
  # handling, SHACL validation, HTML/YAML parsing, image/PDF/spreadsheet
  # manipulation, font tooling, and the Playwright Python binding -
  # small and broadly reusable enough to belong here rather than a
  # persona, the same judgment call as `duckdb`/`sqlite3` below. This is
  # the ONE `python3` this profile provisions: home/ai-harness.nix's
  # `uvx`-launched-MCP-server use case shares this exact interpreter
  # (two different `python3` derivations both trying to provide
  # `bin/python3` would collide in `home.packages`'s buildEnv), so it's
  # a complete, ordinary interpreter first, with this package list as
  # additional site-packages, not a second, separate Python.
  #
  # `pyshacl` and `owlrl` (its own direct dependency) aren't packaged in
  # nixpkgs - vendored as pkgs/pyshacl and pkgs/owlrl, each installing
  # its published PyPI wheel directly, the same "not in nixpkgs" pattern
  # pkgs/specify-cli already uses for an unpackaged tool. `playwright`
  # here is nixpkgs' own Python binding, version-locked (confirmed:
  # 1.52.0, same as `playwright-driver.browsers`/`playwright-test` in
  # home/ai-harness.nix) to the exact browser revision this profile
  # already pins - not a second, independently-tracked browser stack.
  #
  # `config.workspacesHost.extraPythonPackages` (declared below) is how
  # an optional persona (e.g. the `media` persona's `faster-whisper`)
  # adds to this SAME interpreter instead of declaring its own, separate
  # `python3.withPackages` - two different `python3` derivations both
  # trying to provide `bin/python3` would collide in `home.packages`'s
  # buildEnv the moment both are active together. Module-system list
  # options merge automatically, so a persona just sets this option;
  # nothing here has to know which personas exist.
  #
  # `lib.lowPrio`: the `playwright` Python package ships its own
  # `bin/playwright` CLI entry point, same name as `playwright-test`'s
  # Node-based one (home/ai-harness.nix) - a real `home.packages`
  # buildEnv collision the moment both are present together (confirmed
  # directly: `nix flake check` fails with exactly this collision
  # without the fix). Only the *importable module* is actually wanted
  # here (`import playwright`, for a script that drives it directly);
  # `playwright-test`'s Node CLI is the one this repo documents for
  # interactive use (codegen, trace viewer, ...). Deprioritizing this
  # whole env's own `bin/` lets `playwright-test`'s `bin/playwright` win
  # the collision instead of erroring - it doesn't affect what's
  # importable from inside this same interpreter, only which `bin/`
  # entry a name collision resolves to.
  documentPython = lib.lowPrio (pkgs.python3.withPackages (ps: with ps; [
    rdflib
    html5lib
    pyyaml
    pillow
    pypdf
    reportlab
    openpyxl
    pdfplumber
    fonttools
    playwright
  ] ++ [ ported.owlrl ported.pyshacl ] ++ config.workspacesHost.extraPythonPackages));
in
{
  options.workspacesHost.extraPythonPackages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = ''
      Extra packages (from `pkgs.python3Packages`, or a package built
      against that same interpreter) folded into the base profile's one
      `python3.withPackages` environment. Set by an optional persona
      that needs its own Python package without introducing a second,
      colliding `python3` derivation - see home/profiles/media.nix.
    '';
  };

  config.home.packages = (with ported; [
    ws-repos
    ws-persona
    workspaces-host-update
    doctor
    sensitivectl
    specify-cli
    backlog-md
    scaffold-agent-harness
    git-xargs
    ws-start
  ]) ++ [ documentPython ] ++ (with pkgs; [
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
    tree
    blesh
    # GNU Make - not assumed to exist on the base OS image the way it
    # might on a dev machine with build-essential already installed, so
    # it's pinned here like every other tool this flake provisions.
    gnumake
    # curl: install.sh itself needs it to bootstrap, so it's always on
    # the machine before Nix ever runs, but nothing pinned its version
    # afterward - unlike every other tool here, it was floating with
    # whatever the base OS happened to ship.
    curl
    # shellcheck: this repo's own tooling (doctor, ws-repos,
    # workspaces-host-update, install.sh) is almost entirely bash, so a
    # linter for that language belongs in every profile, not just for
    # someone actively contributing.
    shellcheck
    # Scans a repo for anything that looks like a committed secret -
    # `gitleaks detect --source . -v` - the practical backstop for
    # "keeping credentials out of git history" (README) alongside a
    # project's own .gitignore and reviewing `git diff --staged`.
    gitleaks

    # Additional ported utilities (spec 015) general-purpose enough to
    # stay in every profile: a plain HTTP fetcher, a directly-runnable
    # `rclone` (also used internally by pkgs/sensitivectl), and changelog
    # generation. gopass/deno moved to the agent-ops persona in a
    # newbie-simplification pass, since they're more specialized.
    wget
    rclone
    git-chglog

    # Lefthook git hooks manager (spec 016) - a no-op until a project
    # actually adds a lefthook.yml, so it stays available to everyone.
    # See templates/lefthook.yml.example.
    lefthook

    # A local analytical database, small enough on its own that it
    # didn't justify keeping the one-package `data` persona alive once
    # python3/uv (its other two packages) moved to the base profile -
    # see spec 014's "the data persona is removed" revision.
    duckdb

    # The `sqlite3` CLI (spec 015 fifth revision): pairs with `duckdb`
    # for ad hoc inspection of a `.db` file, and several official MCP
    # reference servers (e.g. the sqlite one) expect a plain SQLite
    # database to already be on disk - this is the everyday tool for
    # creating/poking at one by hand, even though the Python-based
    # server itself only needs the `sqlite3` module Python already
    # ships with, not this binary.
    sqlite
  ]);
}
