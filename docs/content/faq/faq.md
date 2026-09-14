## Why this exists {#why-purpose}

I didn't build this for "a nice shell." I built it so a human engineer, a teammate who's new to Linux, a CI/CD pipeline, and an AI coding agent (Claude Code, Codex, an autonomous CI bot, whatever) can all open a terminal on completely different machines and find the exact same structure. The same place repos land (`~/workspaces`, managed by `ws-repos`), the same command to check the environment (`doctor`), the same command to update it (`workspaces-host-update`), the same shell, the same tools, at the same versions. When everyone and everything on a project, engineering, DevOps, an agent working overnight, shares one predictable layout, nobody has to relearn "how this particular machine happens to be set up" before they can do anything useful on it.

That matters more now, not less, because AI put a real command line in front of people who never expected to need one. Just about everyone is an engineer some of the time now, and everyone doing that work deserves the same consistent, capable Linux environment, not a stripped-down one just because they're newer to it. WSL already gives Windows users the desktop, files, and apps they know; this is what gives them the same ready-to-go setup on the Linux side. "New to Linux" stays the only unfamiliar part, not the tooling.

It's also why AI CLIs ship as part of the standard environment (see [Use AI coding agents safely](#day-to-day/ai-agents)). Once someone has an API key configured the safe way this repo documents, they can point an AI harness at their own sandbox and ask it to help fix or improve the setup, the same way it would help with application code. I want that barrier low on purpose. Lowering it is most of the point of building this at all.

Here's the thing worth protecting: that consistency. If an AI harness or a person finds a real improvement while working in one sandbox (a new tool, a better default, an extra `doctor` check, a smarter install step), it belongs in this repo, via a pull request. Not buried in one person's credentials file, not a one-off tweak that only exists on their machine. Your credentials file exists for what's actually personal, your name, your keys, precisely so everything else stays shared. A good idea stuck in one sandbox helps one person. The same idea merged here helps everyone, and every CI run, and every agent, who uses this setup afterward.

## Why Nix and home-manager, not Homebrew/pkgx/mise/chezmoi {#why-nix}

Every one of those tools solves part of this problem. None solves all of it the way a single sandbox needs. A version manager (mise, SDKMAN!) pins one language's runtime, not your shell, your prompt, or your git config. A dotfile templater (chezmoi) manages files, not packages, so you still need something else to install the tools those files configure. Homebrew and pkgx install packages, but not reproducibly enough: "brew install" today and "brew install" in six months can silently resolve to different versions unless you separately pin and audit that yourself.

Nix does the whole job with one mechanism: a lockfile that pins every input, and a package manager that builds from that lockfile into a content-addressed store, so the same commit produces the same closure everywhere, forever. home-manager is the layer that applies that same guarantee to your actual user environment (shell, prompt, dotfiles), not just system packages. Once you have that, you don't need four different tools each solving a slice of the problem with a different reproducibility story. That's Constitution Principle I, and it's the reason nothing else is allowed to sneak into this repository's toolchain.

## Why a plain credentials file, instead of Nix or an encrypted store {#why-credentials-file}

Three reasons.

It never leaves your machine. It lives outside this repo, so `git pull`/`workspaces-host-update` can't touch it, overwrite it, or conflict with it, and there's nothing here you could accidentally commit.

It's protected the way `~/.ssh` or `~/.aws/credentials` are. `workspaces-host-update` sets it to mode 600 every time it runs and fixes the permissions if anything loosens them. `doctor` checks this too.

It's read by a plain script, not by Nix. `workspaces-host-update` parses it as `KEY=value` text. It never `source`s it as a shell script, so a stray backtick or `$(...)` in a token can't run as a command. It writes your git name/email into a file git itself reads automatically, and drops every other token into a per-command-scoped mechanism: a key is only ever visible to the one command that needs it, `gh`/`glab`, or an AI harness CLI, never the rest of your shell.

This is the simplest thing that satisfies Constitution Principle III, secrets never touch the agent's shell unscoped, for the common case. No `age`/`sops` steps just to set your name and email. An opt-in `workspacesHost.secrets` option (`home/secrets.nix`) covers the cases this doesn't: field-level encryption at rest for a genuinely shared team secret (see [Team secrets with sops](#going-further/team-secrets)).

One more piece of this: a project's own `.envrc` should check the ambient environment variable first and only fall back to this sandbox's file, never the other way around. The same project runs in more than one place, your machine, a teammate's, CI/CD, a container, and each gets its credentials differently. In CI/CD, the platform injects the secret directly; there's no credentials file there at all. Get the order backwards and you'd silently overwrite a value CI/CD already injected with the wrong one. `${VAR:-fallback}` does exactly this in one line: in CI/CD the fallback never runs, since the pipeline's own secret already won; on your machine, nothing set it yet, so it falls through to the file.

## Why secrets are scoped per invocation, not exported {#why-secret-scoping}

`claude`/`codex`/`gemini`/`aider`/`gh`/`glab` each get their own bash function of the same name (`home/ai-harness.nix`) that looks for a matching key and sets it only for that one call, never a shell-wide `export`. That's Constitution Principle III, applied literally: a secret gets resolved at the point of use, never as an ambient variable available to the whole shell session and everything running in it, an AI coding agent included. Run `claude` and its wrapper finds the value, sets `$ANTHROPIC_API_KEY` for that one call, and touches nothing else. `echo $ANTHROPIC_API_KEY` in the same window comes back empty. If a CLI has its own browser-based `login` instead (Claude Code and Gemini CLI both do), that works too. The wrapper is a no-op when nothing's configured, and `doctor` only warns if neither a configured credential nor an existing login shows up.

This is non-negotiable given what this repository is for: provisioning environments an AI coding agent operates inside. An agent with an ambient API key in its shell can leak that key into anything it touches, a log line, a generated script, a subprocess it spawns. Scoping the key to the one command that actually needs it closes that door structurally, instead of trusting every tool and every prompt to behave.

## Why Claude Code/Codex/Gemini CLI aren't Nix-packaged like everything else {#why-ai-clis}

They ship near-weekly. Hand-vendoring each one as a Nix derivation means either pinning to a stale version forever or re-deriving a hash on every release, a maintenance job that isn't worth taking on for tools whose entire value is being current. `nodejs`, their shared runtime, gets the declarative treatment instead. Installing the actual CLI stays a single `npm install -g`, the same command upstream already documents.

## Why the base profile stays small, and specialized tools moved to personas {#why-personas}

The base profile stays small on purpose: just what every engineer needs on day one. Compliance tooling, the Java/Postgres toolchain, bulk git tooling, and zero-trust networking clients all live in personas instead, since only some engineers use any given one of them, and a base-profile install is what every other engineer carries around unused. Deciding where a new tool belongs is a single question: does every engineer need this, or only someone doing a specific kind of work? That question is Constitution Principle V, simplicity over completeness, applied directly (see [Add a tool or write a new persona](#going-further/add-a-tool-or-persona) for how that decision plays out in practice).

## Why fish is a persona, not the default {#why-fish}

Bash stays the base profile's shell because every tutorial, every copy-pasted snippet, and most engineers' existing muscle memory already assume it. `blesh` gets bash most of the way to fish's own feel (see [Verify it worked & your first day](#getting-started/first-day/typing-feels-slower-than-youd-expect)) without asking anyone to give that up.

Fish is the honest alternative for someone who wants the real thing: its own native, Rust-implemented (fish 4.x) line editor, nothing layered on top. It's a persona, not a second default, for the same reason Tailscale is a persona and not something this repo joins a mesh for automatically: switching your actual login shell is a consequential, per-engineer choice, not something a package list should decide on your behalf. Activating the `fish` persona only makes `fish` and a matching config available; a separate, deliberate `chsh` step (see [Combine personas for your role](#day-to-day/personas)) is what actually makes it yours.

## Why `ws-repos`, not `mgit`, and why the file suffix still says `.mgit` {#why-ws-repos}

Other, unrelated tools are also named `mgit`. Naming this repository's tool `ws-repos` instead avoids that collision entirely; the directory convention and file matching it implements aren't affected by the rename. (Curious about the tool this one was inspired by? See [Inspiration](#faq/faq/insp-v1).)

The workspace file suffix stays `*.mgit.code-workspace` on purpose: keeping that exact string means a `*.mgit.code-workspace` file written by any tool that recognizes that suffix keeps working here, unchanged.

`ws-repos status` reports a stuck `index.lock` ("locked") and stash count, and separates "untracked" from "dirty." Parsing a `*.mgit.code-workspace` file tolerates the comments VS Code itself allows there, a best-effort filter for `//` and `/* */`, not a full JSONC parser (spec 003's Assumptions document the one edge case that misses).

## Why Deno, Lefthook, and Tailscale/Nebula are scoped the way they are {#why-roadmap}

These three tools trace back to questions the repositories in this project's own lineage raised (see [Inspiration](#faq/faq/insp-v1)); here's how this repository answers each on its own terms.

Deno is provisioned as a plain scripting runtime, available to anyone who wants `deno`+`dax` over `make` for custom project tasks, independent of what `ws-repos`/`doctor` happen to be written in. It lives in the `agent-ops` persona, not the base profile, since it's a specialized enough choice that most engineers won't reach for it on day one.

Lefthook and the zero-trust networking clients (Tailscale, Nebula) are each installed declaratively via Nix, and nothing more. For Lefthook, that means a documented, copy-in example config instead of forcing hooks on every repo. For Tailscale/Nebula, it means installing the client and stopping there: joining an actual mesh (a Tailscale account and its login flow, or a Nebula certificate a network admin issues) is unavoidably a human, out-of-band action, the same category as a git identity or an API key. Constitution Principle III's "provisioning a key is a deliberate, separate, human action" applies just as much to network trust material. Running a server-side control plane is infrastructure someone chooses to operate separately; it's not part of one engineer's sandbox.

## Why not `oh-my-posh enable autoupgrade` {#why-prompt}

Looks like the obvious fix for the "a new release is available" message. It isn't. oh-my-posh's binary lives in the read-only Nix store, so a self-upgrade either fails outright or, worse, succeeds by writing a binary Nix has no record of, which breaks the one guarantee this repository exists to give you: every tool pinned by a lockfile, never resolved against a moving upstream at runtime. The message is silenced correctly instead (`disable_notice` in `home/shell.nix`); that's a cosmetic setting, not a version change. Want a newer oh-my-posh? Bump this flake's nixpkgs pin, the same as updating anything else here.

## Why not SDKMAN! or another Java version manager {#why-java}

Nix already pins a reproducible version for every tool in this setup, Java included. A second version manager on top of that would just duplicate the job. Want a different JDK version or vendor? Override `home/java.nix`'s `pkgs.jdk`/`pkgs.maven` in a fork.

## Why a spec for everything {#why-specs}

A spec-driven workflow feels like ceremony until the alternative shows up: a feature nobody can explain the intent of six months later, or a change that quietly breaks a requirement nobody wrote down in the first place. Every feature here, core and backlog alike, gets a spec (what and why, in testable requirements) and a plan (how, mapped onto this repository's actual files) before code. A spec that no longer matches the code is worse than no spec at all, so a change that breaks a spec's claim updates that spec in the same commit. This isn't process for its own sake: it's what makes it possible to hand this repository to an AI agent and trust that "the spec says X" is still true.

## Why the docs live here, not in the README {#why-docs-architecture}

Two documents claiming to explain the same thing drift apart. One of them updates when a feature changes; the other one, inevitably, doesn't, and now there are two contradictory answers to "how do I set up credentials." Rather than accept that as a cost of having a README *and* a docs site, the README stays a short pointer: what this is, the core concepts, and a link here. This site is the one place installation steps, day-to-day usage, the technical architecture, and every "why" get written down, kept current in the same commit as the change that makes them true. One canonical answer, not two that can disagree.

## Why this site fetches Markdown instead of staying one static HTML file {#why-docs-tech-stack}

The site used to be one self-contained HTML file, every section's prose hand-written directly into the page, specifically so it would work with JavaScript disabled. That held up fine at five flat sections. It stopped holding up once the content needed a real graduated structure, Getting Started, Day to Day, and a light number of Going Further pages, each genuinely use-case driven rather than organized by topic: hand-editing one enormous HTML file for every new page, and hand-maintaining a sidebar that could silently drift from the headings it was supposed to list, was the wrong tradeoff for a site meant to keep growing this way.

Splitting content into plain `.md` files fetched and rendered at navigation time (see [How this documentation site itself works](#going-further/architecture)) fixes both problems: each page is a plain, readable file (readable directly on GitHub too, in a PR diff, anywhere), and the sidebar is generated from real rendered headings instead of hand-copied. The real cost is that JavaScript becomes required to read any content, which the old architecture specifically avoided. That's a deliberate, accepted tradeoff, not an oversight - see spec 018 for the full reasoning.

## v1: [strategy-coach/workspaces-host](https://github.com/strategy-coach/workspaces-host/) {#insp-v1}

The first version of this idea: a chezmoi-based dotfiles repository that called Deno "a core requirement" and carried an unfinished roadmap of its own, including lines for a Git hooks manager and zero-trust networking clients that never got built there. This repository doesn't reuse its code or its chezmoi templates; it takes the idea that a whole engineering sandbox deserves to be one reproducible artifact, and rebuilds it on Nix and home-manager instead.

## mgit: [strategy-coach/workspaces](https://github.com/strategy-coach/workspaces) {#insp-mgit}

A separate tool for keeping many git repositories under one governed directory layout: clone-or-pull idempotently, report status across all of them, and compose a multi-root VS Code workspace from the result. This repository's `ws-repos` follows the same pattern in POSIX shell, deliberately renamed to avoid colliding with the several other, unrelated tools also called `mgit` (see [Why `ws-repos`](#faq/faq/why-ws-repos)).

## v2: [intellectual-frontiers/workspaces-host-v2](https://github.com/intellectual-frontiers/workspaces-host-v2) {#insp-v2}

A second iteration that continued refining the same goal. This repository builds on what v2 established, on its own foundation, rather than carrying its implementation forward line by line.

## This repository: a spiritual successor, not a port {#insp-v3}

workspaces-host-v3 is written from its own spec-driven foundation (see [Extend the repo with an AI agent](#going-further/extend-with-ai)), on Nix and home-manager, with its own constitution governing every decision. It carries forward the goal its predecessors were reaching for, one reproducible sandbox, everywhere, without carrying forward their code, their naming, or an obligation to behave identically to any of them. Using this repository never requires knowing any of the above; every real design decision it makes has its own answer elsewhere in this FAQ, on its own terms.
