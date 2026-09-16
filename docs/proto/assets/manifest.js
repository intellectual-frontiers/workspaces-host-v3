// Prototype scope only: the real site has four tiers and ~16 pages
// (see ../../index.html's own MANIFEST); this one lists just the two
// pages built here, so the nav/sidebar/pager don't link to pages that
// don't exist yet in this experimental directory.
export const TIER_ORDER = ["getting-started", "day-to-day"];

export const MANIFEST = {
  "getting-started": {
    title: "Getting Started",
    pages: [
      { slug: "install", title: "Install" }
    ]
  },
  "day-to-day": {
    title: "Day to Day",
    pages: [
      { slug: "personas", title: "Combine personas for your role" }
    ]
  }
};
