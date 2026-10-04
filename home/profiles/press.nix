{ pkgs, ... }:

let
  # `asciidoctor-with-extensions` run as nixpkgs ships it prints three
  # Bundler warnings on stderr every time ("Source locally installed
  # gems is ignoring #<Bundler::StubSpecification name=rbs|racc|debug
  # ...> because it is missing extensions", spec 037). Its binstubs set
  # GEM_HOME but not GEM_PATH, so RubyGems also searches ruby's own gem
  # directory, whose bundled rbs/racc/debug have no built extensions in
  # nixpkgs' ruby. Nothing here uses them: the gem set is complete
  # (racc is in it, newer). Pointing GEM_PATH at the gem set alone, the
  # same thing nixpkgs' own bundlerApp does for `scripts`, drops those
  # three without hiding anything else.
  asciidoctor = pkgs.symlinkJoin {
    name = "asciidoctor-with-extensions-quiet";
    paths = [ pkgs.asciidoctor-with-extensions ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for exe in $out/bin/*; do
        name=$(basename "$exe")
        rm "$exe"
        makeWrapper ${pkgs.asciidoctor-with-extensions}/bin/$name "$out/bin/$name" \
          --set GEM_PATH ${pkgs.asciidoctor-with-extensions.basicEnv}/${pkgs.ruby.gemPath}
      done
    '';
    inherit (pkgs.asciidoctor-with-extensions) meta;
  };
in
{
  # Book and paper typesetting (spec 025): AsciiDoc-to-PDF/EPUB, and the
  # real LaTeX pipeline underneath a lot of that tooling (dblatex-style
  # document classes, or a manuscript that's just plain LaTeX/XeLaTeX to
  # begin with) - genuinely heavy (texlive's own closure dwarfs most of
  # what else this flake installs), so it's a persona rather than a
  # base-profile addition, the same judgment call as `compliance`/
  # `media`.
  #
  # `asciidoctor-with-extensions` bundles asciidoctor-pdf/-epub3/-diagram/
  # -bibtex/-mathematical together (nixpkgs' own bundlerEnv-pinned gem
  # set) - verified directly: `asciidoctor -r asciidoctor-epub3
  # --version` works. This repository's own docs-src build
  # (pkgs/docs-toolchain) is a separate, narrower build pinned to this
  # repo's exact gem versions for its own manuscript - not reused here on
  # purpose, so a change to one never has to consider the other.
  home.packages = [ asciidoctor ] ++ (with pkgs; [
    poppler_utils
    qpdf
    librsvg
    fontconfig
    jre_headless
    epubcheck
  ]) ++ [
    # texlive.combine, not plain `texlive`: a full TeX Live install is
    # enormous and this persona only needs XeLaTeX plus the collections
    # Debian's own texlive-xetex/texlive-latex-extra/
    # texlive-fonts-recommended/texlive-science packages cover (nixpkgs
    # names its own collections after upstream TeX Live's, not Debian's
    # package names, hence the different-looking attribute names below
    # for the same actual content). `collection-luatex` (spec 032) is
    # Debian's texlive-luatex: LuaLaTeX itself plus `lualatex-math`,
    # `luaotfload` and the rest of what makes `fontspec`/`unicode-math`
    # work under LuaLaTeX, not only XeLaTeX - a print harness that
    # compiles with `lualatex` stopped at "File `lualatex-math.sty' not
    # found" without it.
    (pkgs.texlive.combine {
      inherit (pkgs.texlive)
        scheme-basic
        collection-luatex
        collection-xetex
        collection-latexextra
        collection-fontsrecommended
        collection-mathscience
        latexmk;
    })
  ];
}
