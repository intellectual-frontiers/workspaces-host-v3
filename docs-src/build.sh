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
# NOT YET FULLY VERIFIED end to end - flags here (asciidoctor-diagram's -r
# require, asciidoctor-multipage's converter name, the
# pdf-theme/epub3-stylesheet attribute names) are asciidoctor's documented
# conventions but need a real build to confirm before this script is
# trusted in CI (specs/019-asciidoc-manuscript-docs SC-001).
set -euo pipefail

cd "$(dirname "$0")/.."   # repo root

OUT="${1:-_site}"
BOOK_OUT="$OUT/book"
MANUSCRIPT=docs-src/manuscript.adoc
REQUIRE_DIAGRAM=(-r asciidoctor-diagram)

rm -rf "$OUT"
mkdir -p "$BOOK_OUT/html"

echo "==> single-page HTML"
asciidoctor "${REQUIRE_DIAGRAM[@]}" \
  -a stylesheet=html.css -a stylesdir=docs-src/theme -a linkcss \
  -o "$BOOK_OUT/single-page.html" \
  "$MANUSCRIPT"

echo "==> multi-page HTML"
# asciidoctor-multipage splits the book into one linked file per chapter.
# Falls back to copying the single-page build in as book/html/index.html
# if that converter isn't available, so "Read online" still works end to
# end while multipage support is still being verified (see spec 019's
# Edge Cases: this is a known, accepted partial-success path, not a
# silent failure - it prints which path it took).
if asciidoctor -r asciidoctor-multipage -b multipage_html5 --version >/dev/null 2>&1; then
  asciidoctor "${REQUIRE_DIAGRAM[@]}" -r asciidoctor-multipage -b multipage_html5 \
    -a stylesheet=html.css -a stylesdir=docs-src/theme -a linkcss \
    -D "$BOOK_OUT/html" \
    "$MANUSCRIPT"
else
  echo "    asciidoctor-multipage not available - using the single-page build as book/html/index.html"
  cp "$BOOK_OUT/single-page.html" "$BOOK_OUT/html/index.html"
fi

echo "==> PDF (IF Press imprint)"
cp docs/logo.png docs-src/theme/logo.png   # theme's cover logo; see theme file's own comment
asciidoctor-pdf "${REQUIRE_DIAGRAM[@]}" \
  -a pdf-theme=if-press-pdf-theme.yml -a pdf-themesdir=docs-src/theme \
  -o "$BOOK_OUT/workspaces-host-v3.pdf" \
  "$MANUSCRIPT"
rm -f docs-src/theme/logo.png

echo "==> EPUB"
asciidoctor-epub3 "${REQUIRE_DIAGRAM[@]}" \
  -a epub3-stylesheet=docs-src/theme/epub.css \
  -o "$BOOK_OUT/workspaces-host-v3.epub" \
  "$MANUSCRIPT"

echo "==> assembling deploy artifact"
cp docs/index.html "$OUT/index.html"
cp docs/mascot.jpg docs/mascot-workflows.jpg docs/logo.png docs/social-preview.jpg "$OUT/"
touch "$OUT/.nojekyll"

echo "Build complete: $OUT"
