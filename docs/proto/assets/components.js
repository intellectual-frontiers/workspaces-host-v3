// Shared chrome for the pure-HTML prototype: every page is a real,
// standalone .html file (no client-side Markdown rendering, no hash
// router) - this module defines the custom elements each page drops
// in for its nav, sidebar, pager, footer, and search, so none of that
// markup has to be copy-pasted across files. A page still renders and
// reads fine from "View Source" with JS disabled, just without this
// chrome (see docs/content/going-further/architecture.md's discussion
// of that tradeoff once this becomes the real site).
import { TIER_ORDER, MANIFEST } from "./manifest.js";

// import.meta.url makes every path below correct regardless of how
// deep a page is nested (proto/index.html vs.
// proto/getting-started/install.html) or whether the whole site is
// served from a domain root or a GitHub Pages project subpath
// (intellectual-frontiers.github.io/workspaces-host-v3/) - no
// hand-maintained "../../" and no build step to compute it instead.
const ASSETS_URL = new URL(".", import.meta.url); // .../proto/assets/
const SITE_ROOT = new URL("..", ASSETS_URL); // .../proto/
const DOCS_ROOT = new URL("..", SITE_ROOT); // .../docs/ (logo.png, mascot.jpg, vendor/ all live here)

function pageHref(tierId, slug) {
  return new URL(tierId + "/" + slug + ".html", SITE_ROOT).href;
}

function flattenedPages() {
  var flat = [];
  TIER_ORDER.forEach(function (tierId) {
    var tier = MANIFEST[tierId];
    if (!tier) return;
    tier.pages.forEach(function (p) {
      flat.push({ tierId: tierId, tierTitle: tier.title, slug: p.slug, title: p.title });
    });
  });
  return flat;
}

// Same auto-slugify + `{#exact-id}` override as the live site's
// buildPageToc, so a heading edit can't drift out of sync with a
// hand-maintained sidebar.
var EXPLICIT_ID_RE = /\s*\{#([a-z0-9-]+)\}\s*$/i;
function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .trim()
    .replace(/\s+/g, "-");
}

function buildPageToc(root) {
  var used = {};
  var toc = [];
  root.querySelectorAll("h2, h3").forEach(function (h) {
    var explicit = EXPLICIT_ID_RE.exec(h.textContent);
    var base;
    if (explicit) {
      base = explicit[1];
      h.innerHTML = h.innerHTML.replace(EXPLICIT_ID_RE, "");
    } else {
      base = slugify(h.textContent);
    }
    var id = base;
    var n = 2;
    while (used[id]) {
      id = base + "-" + n;
      n++;
    }
    used[id] = true;
    h.id = id;
    toc.push({ id: id, text: h.textContent, level: h.tagName === "H2" ? 2 : 3 });
  });
  return toc;
}

function escapeHtml(s) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

class SiteNav extends HTMLElement {
  connectedCallback() {
    var current = this.getAttribute("current") || "";
    var html = '<div class="site-nav-inner">';
    html +=
      '<a class="brand" href="' + new URL("index.html", SITE_ROOT).href + '">' +
      '<img src="' + new URL("logo.png", DOCS_ROOT).href + '" alt="" width="128" height="128">Workspaces Host</a>';
    TIER_ORDER.forEach(function (tierId) {
      var tier = MANIFEST[tierId];
      var firstPage = tier.pages[0];
      var cls = tierId === current ? "nav-link current" : "nav-link";
      html +=
        '<a class="' + cls + '" data-tier="' + tierId + '" href="' + pageHref(tierId, firstPage.slug) + '">' +
        tier.title + "</a>";
    });
    html += '<span class="spacer"></span><site-search></site-search>';
    html += '<a class="gh-link" href="https://github.com/intellectual-frontiers/workspaces-host-v3">GitHub &#8599;</a>';
    html += "</div>";
    this.innerHTML = html;
  }
}

class SiteSidebar extends HTMLElement {
  connectedCallback() {
    var tierId = this.getAttribute("tier");
    var pageSlug = this.getAttribute("page");
    var tier = MANIFEST[tierId];
    if (!tier) return;
    var main = document.querySelector("main.content");
    var pageToc = main ? buildPageToc(main) : [];
    var html = "<ul>";
    tier.pages.forEach(function (p) {
      var isCurrent = p.slug === pageSlug;
      var cls = isCurrent ? ' class="current-page"' : "";
      html += "<li><a" + cls + ' href="' + pageHref(tierId, p.slug) + '">' + p.title + "</a></li>";
      if (isCurrent) {
        pageToc.forEach(function (h) {
          html +=
            '<li class="sub' + (h.level === 3 ? " sub-heading-3" : "") + '"><a href="#' + h.id + '">' +
            h.text + "</a></li>";
        });
      }
    });
    html += "</ul>";
    this.innerHTML = html;
  }
}

class SitePager extends HTMLElement {
  connectedCallback() {
    var tierId = this.getAttribute("tier");
    var pageSlug = this.getAttribute("page");
    var flat = flattenedPages();
    var idx = -1;
    for (var i = 0; i < flat.length; i++) {
      if (flat[i].tierId === tierId && flat[i].slug === pageSlug) {
        idx = i;
        break;
      }
    }
    if (idx === -1) return;
    var prev = idx > 0 ? flat[idx - 1] : null;
    var next = idx < flat.length - 1 ? flat[idx + 1] : null;
    var html = '<nav class="page-pager" aria-label="Page navigation">';
    if (prev) {
      html +=
        '<a class="pager-link pager-prev" href="' + pageHref(prev.tierId, prev.slug) + '">' +
        '<span class="pager-label">&larr; Previous</span><span class="pager-title">' + prev.title + "</span></a>";
    } else {
      html += '<span class="pager-link pager-empty"></span>';
    }
    if (next) {
      html +=
        '<a class="pager-link pager-next" href="' + pageHref(next.tierId, next.slug) + '">' +
        '<span class="pager-label">Next &rarr;</span><span class="pager-title">' + next.title + "</span></a>";
    } else {
      html += '<span class="pager-link pager-empty"></span>';
    }
    html += "</nav>";
    this.innerHTML = html;
  }
}

class SiteFooter extends HTMLElement {
  connectedCallback() {
    this.innerHTML =
      '<footer class="site-footer"><p><a href="https://github.com/intellectual-frontiers/workspaces-host-v3">intellectual-frontiers/workspaces-host-v3</a> &middot; MIT License</p></footer>';
  }
}

// Builds and queries a MiniSearch index over every prototype page's
// rendered <main> text, fetched via fetch()+DOMParser rather than a
// separate Markdown source (there isn't one any more - the .html file
// *is* the content). Mirrors ../../index.html's search box, including
// the fix for the bug where focusing with no query left "Loading
// search index..." on screen forever once the index resolved.
var searchIndexPromise = null;
function buildSearchIndex() {
  if (!searchIndexPromise) {
    var docs = [];
    TIER_ORDER.forEach(function (tierId) {
      var tier = MANIFEST[tierId];
      tier.pages.forEach(function (page) {
        var url = pageHref(tierId, page.slug);
        docs.push(
          fetch(url)
            .then(function (r) { return r.text(); })
            .then(function (html) {
              var dom = new DOMParser().parseFromString(html, "text/html");
              var main = dom.querySelector("main.content");
              var body = main ? main.textContent.replace(/\s+/g, " ").trim() : "";
              return {
                id: tierId + "/" + page.slug,
                tierId: tierId,
                tierTitle: tier.title,
                pageSlug: page.slug,
                title: page.title,
                body: body
              };
            })
        );
      });
    });
    searchIndexPromise = Promise.all(docs).then(function (allDocs) {
      var mini = new MiniSearch({
        fields: ["title", "body"],
        storeFields: ["title", "tierId", "tierTitle", "pageSlug", "body"],
        searchOptions: { prefix: true, fuzzy: 0.2, boost: { title: 3 } }
      });
      mini.addAll(allDocs);
      return mini;
    });
  }
  return searchIndexPromise;
}

function snippetFor(body, query) {
  var idx = body.toLowerCase().indexOf(query.toLowerCase());
  if (idx === -1) return body.slice(0, 140);
  var start = Math.max(0, idx - 40);
  return (start > 0 ? "…" : "") + body.slice(start, start + 160) + "…";
}

function highlightSnippet(snippet, query) {
  var escaped = escapeHtml(snippet);
  if (!query) return escaped;
  var re = new RegExp("(" + query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + ")", "ig");
  return escaped.replace(re, "<mark>$1</mark>");
}

class SiteSearch extends HTMLElement {
  connectedCallback() {
    this.innerHTML =
      '<input type="search" id="search-input" placeholder="Search&hellip; (press /)" aria-label="Search this site" autocomplete="off" spellcheck="false" />';

    // A sibling of this element, appended straight to <body> - not
    // nested in here - for the same reason ../../index.html keeps
    // #search-results outside .site-nav: an ancestor with
    // overflow-x: auto (site-nav-inner) clips any descendant,
    // positioned or not. position: fixed plus JS-computed coordinates
    // (positionResults, below) escapes that clip entirely.
    var box = document.createElement("div");
    box.className = "search-results";
    box.hidden = true;
    document.body.appendChild(box);

    var input = this.querySelector("#search-input");

    function closeResults() {
      box.hidden = true;
      box.innerHTML = "";
    }

    function positionResults() {
      var rect = input.getBoundingClientRect();
      box.style.top = rect.bottom + 6 + "px";
      box.style.left = rect.left + "px";
      box.style.width = rect.width + "px";
    }

    function renderResults(results, query) {
      if (!results.length) {
        box.innerHTML = '<div class="search-status">No results for &ldquo;' + escapeHtml(query) + "&rdquo;</div>";
        positionResults();
        box.hidden = false;
        return;
      }
      var html = "";
      results.slice(0, 8).forEach(function (r, i) {
        var snippet = highlightSnippet(snippetFor(r.body, query), query);
        html +=
          '<a class="search-result' + (i === 0 ? " active" : "") + '" href="' + pageHref(r.tierId, r.pageSlug) + '">' +
          '<span class="search-result-title">' + escapeHtml(r.title) +
          '<span class="search-result-tier">' + escapeHtml(r.tierTitle) + "</span></span>" +
          '<span class="search-result-snippet">' + snippet + "</span>" +
          "</a>";
      });
      box.innerHTML = html;
      positionResults();
      box.hidden = false;
    }

    function ensureIndex() {
      if (!searchIndexPromise) {
        box.innerHTML = '<div class="search-status">Loading search index&hellip;</div>';
        positionResults();
        box.hidden = false;
      }
      return buildSearchIndex();
    }

    input.addEventListener("focus", function () {
      ensureIndex().then(function (mini) {
        var query = input.value.trim();
        if (query) {
          renderResults(mini.search(query), query);
        } else {
          // Same fix as ../../index.html: nothing else clears the
          // "Loading search index..." message once it resolves if
          // there's no query to search, so it would otherwise sit
          // there looking stuck forever.
          closeResults();
        }
      });
    });

    input.addEventListener("input", function () {
      var query = input.value.trim();
      if (!query) {
        closeResults();
        return;
      }
      ensureIndex().then(function (mini) {
        if (input.value.trim() !== query) return;
        renderResults(mini.search(query), query);
      });
    });

    input.addEventListener("keydown", function (e) {
      var results = box.querySelectorAll(".search-result");
      if (e.key === "Escape") {
        e.preventDefault();
        closeResults();
        input.blur();
        return;
      }
      if (e.key === "Enter") {
        var active = box.querySelector(".search-result.active") || results[0];
        if (active) {
          e.preventDefault();
          active.click();
        }
        return;
      }
      if ((e.key === "ArrowDown" || e.key === "ArrowUp") && results.length) {
        e.preventDefault();
        var current = box.querySelector(".search-result.active");
        var idx = current ? Array.prototype.indexOf.call(results, current) : -1;
        idx = e.key === "ArrowDown" ? Math.min(idx + 1, results.length - 1) : Math.max(idx - 1, 0);
        results.forEach(function (r) { r.classList.remove("active"); });
        results[idx].classList.add("active");
        results[idx].scrollIntoView({ block: "nearest" });
      }
    });

    box.addEventListener("click", function (e) {
      if (!e.target.closest(".search-result")) return;
      closeResults();
      input.blur();
    });

    document.addEventListener("click", function (e) {
      if (!input.contains(e.target) && !box.contains(e.target)) closeResults();
    });

    window.addEventListener("scroll", closeResults, { passive: true });
    window.addEventListener("resize", function () {
      if (!box.hidden) positionResults();
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "/" && document.activeElement !== input) {
        e.preventDefault();
        input.focus();
      }
    });
  }
}

customElements.define("site-nav", SiteNav);
customElements.define("site-sidebar", SiteSidebar);
customElements.define("site-pager", SitePager);
customElements.define("site-footer", SiteFooter);
customElements.define("site-search", SiteSearch);

// vendor/mermaid.min.js is ~5.5MB, so it's only worth loading on a
// page that actually has a diagram. A prototype page hand-authors
// <div class="mermaid"> directly (no fenced-code-block conversion
// step needed, since there's no Markdown rendering step any more).
(function loadMermaidIfNeeded() {
  var diagrams = document.querySelectorAll(".mermaid");
  if (!diagrams.length) return;
  var script = document.createElement("script");
  script.src = new URL("vendor/mermaid.min.js", DOCS_ROOT).href;
  script.onload = function () {
    mermaid.initialize({ startOnLoad: false, theme: "neutral", securityLevel: "strict" });
    mermaid.run({ nodes: diagrams });
  };
  document.head.appendChild(script);
})();

// Purely additive: wraps each <pre> in main in a .code-block and adds
// a Copy button, same as ../../index.html's enhanceCodeBlocks.
(function enhanceCodeBlocks() {
  var main = document.querySelector("main.content");
  if (!main) return;
  main.querySelectorAll("pre").forEach(function (pre) {
    var wrapper = document.createElement("div");
    wrapper.className = "code-block";
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);

    var btn = document.createElement("button");
    btn.className = "copy-btn";
    btn.type = "button";
    btn.textContent = "Copy";
    wrapper.appendChild(btn);

    btn.addEventListener("click", function () {
      var text = pre.textContent.replace(/^\$ /gm, "");
      navigator.clipboard.writeText(text).then(
        function () {
          btn.textContent = "Copied";
          setTimeout(function () { btn.textContent = "Copy"; }, 1500);
        },
        function () {
          btn.textContent = "Select + Ctrl/Cmd-C";
          setTimeout(function () { btn.textContent = "Copy"; }, 2000);
        }
      );
    });
  });
})();
