{ pkgs }:

let
  py = pkgs.python3Packages;

  # specify-cli's pyproject.toml declares typer>=0.24.0 and json5>=0.13.0,
  # newer than this flake's pinned nixpkgs ships. Nix doesn't enforce those
  # bounds at build time, but typer 0.12 predates specify-cli's actual usage
  # (newer Rich-based error rendering typer added since), so it's bumped via
  # overridePythonAttrs; json5 likewise, since `specify check`/`init` call
  # its dumps() with options only present in 0.13+. click's own nixpkgs
  # version (8.1.7) already satisfies typer's own `click>=8.0.0` and is left
  # alone - bumping it too would require a newer flit-core than this
  # nixpkgs pin ships, to build click's PEP 639 metadata.
  typer' = py.typer.overridePythonAttrs (_old: rec {
    version = "0.19.2";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/21/ca/950278884e2ca20547ff3eb109478c6baf6b8cf219318e6bc4f666fad8e8/typer-${version}.tar.gz";
      sha256 = "9ad824308ded0ad06cc716434705f691d4ee0bfd0fb081839d2e426860e7fdca";
    };
    propagatedBuildInputs = [ py.click py.typing-extensions py.shellingham py.rich ];
  });

  json5' = py.json5.overridePythonAttrs (_old: rec {
    version = "0.15.0";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/e4/7d/05c46a96a78147ae3bf99c2f4169ce144a70220b8d6fcd56f6ec368b8ce9/json5-${version}.tar.gz";
      sha256 = "7424d1f1eb1d56da6e3d70643f53619862b4ce81440bdb8ecfd6f875e5ba4a71";
    };
  });
in
py.buildPythonApplication {
  pname = "specify-cli";
  version = "1.0.7.dev0";
  pyproject = true;

  # builtins.fetchGit (evaluated by the nix CLI process itself, using its own
  # network/TLS setup - same path flake.nix's git+https inputs use) rather
  # than pkgs.fetchgit (a sandboxed fixed-output derivation build, which in
  # this sandbox can't validate the egress proxy's TLS certificate the way
  # the outer nix process can).
  src = builtins.fetchGit {
    url = "https://github.com/github/spec-kit.git";
    rev = "cdfbc5673990b196039f1131730aa02ceb04024e";
  };

  build-system = [ py.hatchling ];

  # The runtime-deps check enforces pyproject.toml's declared lower bounds
  # (typer>=0.24.0, click>=8.2.1) literally; typer is bumped above to 0.19.2
  # (still short of 0.24) and click is left at nixpkgs' 8.1.7 (bumping it
  # needs a newer flit-core than this pin ships) - both relaxed here since
  # specify-cli's actual code only exercises typer/click APIs stable well
  # below those floors, verified by running the built CLI end-to-end.
  pythonRelaxDeps = [ "click" "typer" "json5" ];

  dependencies = [
    typer'
    py.click
    py.rich
    py.platformdirs
    py.readchar
    py.pyyaml
    py.packaging
    py.pathspec
    json5'
  ];

  pythonImportsCheck = [ "specify_cli" ];

  meta = {
    description = "GitHub Spec Kit's specify CLI - bootstraps spec-driven development projects";
    mainProgram = "specify";
  };
}
