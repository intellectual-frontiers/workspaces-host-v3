{ pkgs, ... }:

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
  home.packages = (with pkgs; [
    asciidoctor-with-extensions
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
