#!/usr/bin/env bash
# Builds all four docs formats from docs-src/manuscript.adoc into a
# combined, deploy-ready directory (docs/index.html + generated book/).
#
# Run with pkgs.docs-toolchain's bin/ on PATH (`nix build .#docs-toolchain`
# then add result/bin to PATH) - see pkgs/docs-toolchain (specs/019
# FR-007): asciidoctor + asciidoctor-pdf + asciidoctor-epub3 +
# asciidoctor-multipage, each wrapped with mermaid-cli on PATH for
# asciidoctor-diagram's `[mermaid]` blocks, pinned via
# pkgs/docs-toolchain/{Gemfile.lock,gemset.nix}.
#
# Usage: docs-src/build.sh [output-dir]   (default: _site)
#
# Verified end to end against pkgs/docs-toolchain (single-page HTML,
# multi-page HTML, PDF, and EPUB all build and embed a real rendered
# Mermaid diagram, not raw source or a broken image reference).
set -euo pipefail

cd "$(dirname "$0")/.."   # repo root
ROOT="$(pwd)"
THEME="$ROOT/docs-src/theme"

OUT="${1:-_site}"
BOOK_OUT="$OUT/book"
MANUSCRIPT=docs-src/manuscript.adoc
# asciidoctor-diagram's mermaid converter shells out to mermaid-cli's
# mmdc via Puppeteer/headless Chromium, which refuses to launch as root
# with no sandbox flags - true of this development sandbox, and possibly
# of some CI runners too. docs-src/theme/puppeteer-config.json passes
# --no-sandbox through to it; harmless when not running as root.
#
# Two things about the attribute name and path both matter, confirmed
# by reading asciidoctor-diagram's own diagram_source.rb: a document
# (not block) level attribute is only picked up under a diagram-type
# prefix ("mermaid-puppeteer-config", not the bare "puppeteer-config"
# the CHANGELOG's own wording suggests), and the path must be absolute
# since it's resolved relative to whichever chapter file is being
# processed, not the working directory this script runs from - true of
# pdf-themesdir/epub3-stylesheet below too. The HTML5 stylesheet is
# different again: `stylesheet`/`linkcss` write the attribute's raw
# value straight into <link href>, with no path resolution at all, so
# it has to be a path that's actually correct relative to wherever the
# generated HTML file ends up - simplest fix is copying html.css next
# to each HTML output and referencing it with no directory prefix.
REQUIRE_DIAGRAM=(-r asciidoctor-diagram -a "mermaid-puppeteer-config=$THEME/puppeteer-config.json")

rm -rf "$OUT"
mkdir -p "$BOOK_OUT/html"
cp "$THEME/html.css" "$BOOK_OUT/html.css"
cp "$THEME/html.css" "$BOOK_OUT/html/html.css"

echo "==> single-page HTML"
asciidoctor "${REQUIRE_DIAGRAM[@]}" \
  -a stylesheet=html.css -a linkcss \
  -o "$BOOK_OUT/single-page.html" \
  "$MANUSCRIPT"

echo "==> multi-page HTML"
# asciidoctor-multipage splits the book into one linked file per chapter,
# with its own real navigation built in: each chapter page gets a full
# table-of-contents sidebar (in #toc, current chapter marked
# .toc-current) plus an Up/Home/Previous/Next pager (.nav-footer) - no
# hand-rolled nav needed, just styling for what it already generates
# (see docs-src/theme/html.css). Falls back to copying the single-page
# build in as book/html/index.html if the converter isn't available, so
# "Read online" still works end to end (spec 019's Edge Cases: a known,
# accepted partial-success path, not a silent failure - it prints which
# path it took).
if asciidoctor -r asciidoctor-multipage -b multipage_html5 --version >/dev/null 2>&1; then
  asciidoctor "${REQUIRE_DIAGRAM[@]}" -r asciidoctor-multipage -b multipage_html5 \
    -a stylesheet=html.css -a linkcss \
    -D "$BOOK_OUT/html" \
    "$MANUSCRIPT"
  # asciidoctor-multipage names the landing/TOC page after the source
  # file (manuscript.html) - every internal nav link (TOC root, "Home")
  # already points there, so this is an added copy at the conventional
  # index.html name for docs/index.html's own "Read online" link, not a
  # replacement.
  cp "$BOOK_OUT/html/manuscript.html" "$BOOK_OUT/html/index.html"
else
  echo "    asciidoctor-multipage not available - using the single-page build as book/html/index.html"
  cp "$BOOK_OUT/single-page.html" "$BOOK_OUT/html/index.html"
fi

echo "==> PDF (IF Press imprint)"
cp docs/logo.png "$THEME/logo.png"   # theme's cover logo; see theme file's own comment
asciidoctor-pdf "${REQUIRE_DIAGRAM[@]}" \
  -a pdf-theme=if-press-pdf-theme.yml -a "pdf-themesdir=$THEME" \
  -o "$BOOK_OUT/workspaces-host-v3.pdf" \
  "$MANUSCRIPT"
rm -f "$THEME/logo.png"

echo "==> EPUB"
asciidoctor-epub3 "${REQUIRE_DIAGRAM[@]}" \
  -a "epub3-stylesheet=$THEME/epub.css" \
  -o "$BOOK_OUT/workspaces-host-v3.epub" \
  "$MANUSCRIPT"

echo "==> assembling deploy artifact"
cp docs/index.html "$OUT/index.html"
cp docs/mascot.jpg docs/mascot-workflows.jpg docs/logo.png docs/social-preview.jpg "$OUT/"
touch "$OUT/.nojekyll"

echo "Build complete: $OUT"
