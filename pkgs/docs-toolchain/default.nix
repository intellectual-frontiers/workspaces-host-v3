{ pkgs }:

let
  # asciidoctor-pdf, asciidoctor-epub3, asciidoctor-diagram and
  # asciidoctor-multipage aren't packaged anywhere in nixpkgs (checked
  # both top-level and `rubyPackages.*` against this flake's pinned
  # nixos-25.05 revision) - only plain `asciidoctor` is. `bundlerEnv`
  # is nixpkgs' idiomatic way to pull in an arbitrary Ruby gem set
  # reproducibly: Gemfile.lock and gemset.nix (generated with `bundle
  # lock` + `bundix`, see the README-style comment below) pin every
  # gem and its exact source hash, so this resolves against a
  # lockfile rather than rubygems.org at build time - same guarantee
  # Constitution Principle I asks of everything else this repo
  # provisions.
  #
  # To regenerate Gemfile.lock/gemset.nix after editing Gemfile (e.g.
  # bumping a gem):
  #   nix shell nixpkgs#ruby nixpkgs#bundler nixpkgs#bundix -c bash -c \
  #     'cd pkgs/docs-toolchain && bundle lock && bundix -l'
  gems = pkgs.bundlerEnv {
    name = "docs-toolchain-gems";
    ruby = pkgs.ruby;
    gemdir = ./.;
  };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "docs-toolchain";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    # asciidoctor-diagram (loaded via `-r asciidoctor-diagram`) shells
    # out to `mmdc` (mermaid-cli's binary) at build time to render
    # `[mermaid]` blocks to static SVG/PNG - putting it on each
    # wrapped binary's PATH is what makes that "no diagram JS ships to
    # the reader" path work without every docs-build invocation
    # having to know to add it itself.
    for bin in asciidoctor asciidoctor-pdf asciidoctor-epub3 asciidoctor-multipage; do
      makeWrapper ${gems}/bin/$bin $out/bin/$bin \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.mermaid-cli ]}
    done
    runHook postInstall
  '';

  passthru = {
    inherit gems;
  };

  meta = {
    description = "Asciidoctor plus PDF/EPUB3 backends, asciidoctor-diagram and mermaid-cli, pinned via Gemfile.lock/gemset.nix, for building docs/ from a single AsciiDoc manuscript";
  };
}
