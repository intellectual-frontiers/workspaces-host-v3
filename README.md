# workspaces-host-v3

A ready-to-use engineering sandbox for your own computer. One command gives
you a configured bash shell and prompt, git and GitHub/GitLab credentials
handled safely, a way to keep many git repositories organized, and a
growing set of everyday developer tools — set up identically every time,
whether that's on Windows (via WSL), Linux, a Mac, inside a container, or
in a cloud AI-agent session.

It's built with **Nix flakes + home-manager**: the whole setup is
described in code (this repository) rather than a list of manual steps,
so it rebuilds byte-for-byte the same way anywhere, and a future update to
it is just a `git pull` plus one command away (see "Keeping your sandbox
in sync" below).

See [`.specify/memory/constitution.md`](.specify/memory/constitution.md) for
the principles behind these design choices, and [`specs/`](specs/) for the
requirements each feature implements.

## Installation

<details>
<summary><strong>New to Nix? Three sentences on what's actually happening</strong></summary>

**Nix** is a package manager that installs exact, pinned versions of every tool (bash, git, all of
it) into an isolated store, instead of whatever versions your OS happens to have. **A flake** is
just this repository's own description, in one file (`flake.nix`), of exactly which tools and
settings make up your environment. **home-manager** is what actually applies that description to
your user account — each time it does, it creates a new **generation** (a complete, numbered
snapshot you can switch back to instantly; see "rolling back" below) rather than editing your
files in place. You don't need to know any more than this to use everything below.

</details>

**If you're on Windows, start here** — that's what most people reading
this want. Already on Linux or a Mac? Skip ahead to "Other platforms."

### Windows (via WSL) — start here

WSL turns on a real Linux system that runs alongside your normal Windows
apps. Everything below happens inside that Linux system (a window titled
"Debian"), except step 1.

1. **Open PowerShell as Administrator** and run:
   ```powershell
   wsl --install -d Debian
   ```
   This may ask you to restart your computer.
2. **Open "Debian"** from the Start menu. The first time it opens, choose
   a Linux username and password (separate from your Windows login).
3. **From inside that Debian window, run this one line**:
   ```console
   $ sudo apt-get update && sudo apt-get install -y curl git && sh -c "$(curl -fsSL https://raw.githubusercontent.com/intellectual-frontiers/workspaces-host-v3/main/install.sh)"
   ```
   `sudo` asks for the password from step 2 — the only password prompt in
   this whole process. The line can take a few minutes the first time,
   and is safe to run again later (it skips whatever's already done, and
   just updates/reapplies otherwise — that's what `workspaces-host-update`
   does under the hood once you're set up).

   <details>
   <summary><strong>Why does this command start with <code>apt-get install curl git</code>?</strong></summary>

   A brand-new Debian/WSL image doesn't include `curl` yet (nothing does, on a minimal install) -
   so a one-liner that starts with `curl -fsSL https://.../install.sh` can't even fetch itself on
   a fresh machine. This first installs just enough (`curl`, `git`) to fetch and run the actual
   installer, which then does everything else itself, including detecting and installing anything
   *it* still needs (Nix's own `xz` dependency, for instance).

   </details>

4. **Fill in your credentials, then apply them:**
   ```console
   $ nano ~/.config/workspaces-host/credentials
   $ workspaces-host-update
   ```
   `workspaces-host-update` applies it and finishes by running `doctor`,
   so you see a `PASS`/`WARN`/`FAIL` line for everything right there in
   the same command — a `WARN` for anything you left blank is normal.

That's it — **close this window and open a new one** (step 3 already set
your login shell, but this window is still whatever you started in). Look
for the new prompt and autosuggestions appearing as you type to confirm it
took.

If a new window doesn't look/feel any different, step 3's automatic
`chsh` may not have succeeded (a locked-down `/etc`, no `sudo`) — `doctor`
will tell you, with the exact command to fix it yourself.

<details>
<summary><strong>Why keep project repos under <code>~/workspaces</code>, not <code>/mnt/c/Users/...</code>?</strong></summary>

WSL can access Windows' files from Linux and vice versa, but it's slow across that boundary — git
especially — and it's exactly what a WSL warning about "an I/O intensive operation like git" is
telling you if you ever see one. `doctor` checks for this too, for both `$HOME` and wherever you
happen to be standing when you run it. See "Managing your repos" below for the tool that keeps
every repo under `~/workspaces` automatically.

</details>

### Using VS Code with this setup (WSL)

This repo doesn't install VS Code itself. If `code .` from inside your
Debian window opens the **Windows** copy of VS Code (or errors), that's
WSL doing exactly what it's designed to do — Microsoft's own supported way
to edit WSL files in VS Code is to let it do that:

1. Install VS Code on **Windows** (not inside Debian) from
   [code.visualstudio.com](https://code.visualstudio.com/).
2. Install the **"WSL" extension** in that Windows VS Code (published by
   Microsoft).
3. From inside your Debian window, in any project folder: `code .` — the
   first time, this installs a small VS Code Server *inside* WSL (needs
   network access, takes a minute), then opens a normal VS Code window —
   editing, the terminal, and every extension run inside Linux, even
   though the window itself is a Windows application.

If step 3 still fails after installing the extension, it's almost always
the VS Code Server install — `code --version` from inside WSL confirms
whether it landed; closing and reopening the Debian window (fresh `$PATH`)
before retrying resolves it in most cases.

### Other platforms (Linux or macOS, no WSL)

Open a regular terminal (nothing WSL-specific applies) and run the
manual equivalent below. The one thing that differs by platform is how
you get `curl`/`git` (and Nix's own `xz` dependency) on the system in the
first place, since `install.sh` can't run until something has fetched it:

- **Linux (a VM, or directly on a real machine)**: many VM/cloud images
  already have `curl`/`git`/`xz`; a genuinely minimal one (the same gap
  as fresh WSL/Debian above) won't. If `curl -V` says "command not
  found," install them with your distro's own package manager first —
  `sudo apt-get install -y curl git xz-utils` (Debian/Ubuntu), `sudo dnf
  install -y curl git xz` (RHEL/Fedora/CentOS), or `sudo pacman -Sy
  --noconfirm curl git xz` (Arch) — then run the same one-liner as step 3
  above (without the `apt-get install` prefix, which was WSL/Debian-
  specific). `install.sh` itself auto-detects whichever of those three
  families you're on for anything it still needs. Want to build/run this
  repository's container images? Also install Docker: `sudo apt install
  -y docker.io` (Debian/Ubuntu — see
  [docs.docker.com](https://docs.docker.com/engine/install/) for another
  distro's package).
- **macOS**: `curl`, `git`, and `xz` are always already there (Apple ships
  all three) — just run the plain one-liner from step 3 above (no
  `apt-get`/`dnf`/`pacman` prefix), Apple Silicon or Intel; it senses your
  system automatically (via `current`). Container sandboxing (spec 005's
  network-restricted image) isn't available on macOS — everything else
  is.
- **A Linux distro `install.sh` doesn't recognize**: it tells you exactly
  that and exits without changing anything — install `curl`/`git`/`xz`
  yourself, then re-run it; every step after that is distro-agnostic.

**Windows without WSL:** not possible — Nix needs a real Linux or macOS
system underneath it, and WSL (above) is exactly that, so it's the only
Windows path.

### Manual equivalent, if you'd rather run each step yourself

```console
$ sudo apt update && sudo apt install -y curl git xz-utils   # skip on macOS
$ sh <(curl -L https://nixos.org/nix/install) --no-daemon
$ mkdir -p ~/.config/nix
$ echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
$ git clone https://github.com/intellectual-frontiers/workspaces-host-v3.git ~/.workspaces-host-v3
$ cd ~/.workspaces-host-v3
$ nix build ".#homeConfigurations.current.activationPackage" --impure
$ export HOME_MANAGER_BACKUP_EXT=pre-workspaces-host-backup
$ ./result/activate
```

`install.sh` (in this repo) is the actual source of truth for these steps
— both are plain, readable shell, worth a skim before you pipe them into
a shell either way.

## Setting up your credentials

Your git name/email and GitHub/GitLab tokens all go in **one plain text
file, outside this repository entirely**: `~/.config/workspaces-host/credentials`.
It's just `KEY=value` lines — no Nix syntax, no encryption tool to learn
first — and `workspaces-host-update` creates a blank one for you the
first time you run it.

```console
$ nano ~/.config/workspaces-host/credentials
```
```dotenv
GIT_NAME=Your Name
GIT_EMAIL=you@example.com

GITHUB_TOKEN=ghp_yourToken
GITLAB_TOKEN=

ANTHROPIC_API_KEY=sk-ant-yourRealKey
OPENAI_API_KEY=
GEMINI_API_KEY=
```
```console
$ workspaces-host-update
```

That one command re-applies your setup with the new values *and* finishes
by running `doctor`, so you see immediately whether everything took
effect.

<details>
<summary><strong>Why a plain file outside the repo, instead of Nix or an encrypted store?</strong></summary>

This file:

- **Never leaves your machine.** It lives outside this repository, so
  `git pull`/`workspaces-host-update` can never touch, overwrite, or
  conflict with it, and there's nothing here to accidentally commit.
- **Is protected the same way `~/.ssh` or `~/.aws/credentials` are**:
  `workspaces-host-update` sets it to mode 600 every time it runs, and
  fixes the permissions automatically if anything ever loosens them;
  `doctor` checks this too.
- **Is read by a plain script, not by Nix.** `workspaces-host-update`
  parses it as plain `KEY=value` text (never `source`s it as a shell
  script, so a stray backtick or `$(...)` in a token can't be executed as
  a command), writes your git name/email into a file git itself includes
  automatically, and drops each token into a per-command-scoped
  mechanism — a key is only ever visible to the one command that
  actually needs it (`gh`/`glab`, or an AI harness CLI — see "Setting up
  AI harness credentials" below), never the rest of your shell.

This is the simplest thing that actually satisfies Constitution Principle III ("secrets never
touch the agent's shell unscoped") for the common case — no `age`/`sops` steps required just to
set your name and email. The advanced sops-based path below exists for the cases this doesn't
cover.

</details>

**Rotating a token**: edit the same line and run `workspaces-host-update`
again — no encrypted file to regenerate, no old plaintext left behind.

**Something else that needs a credential** (a cloud provider token, a
project-specific API key)? Add it to this same file with whatever name
makes sense (e.g. `AWS_ACCESS_KEY_ID=...`) — `workspaces-host-update`
writes any line that isn't `GIT_NAME`/`GIT_EMAIL` into
`~/.local/state/workspaces-host/secrets/env/<NAME>`, ready for a
project's own `.envrc` to pick up:

```console
$ cat .envrc
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-$(cat ~/.local/state/workspaces-host/secrets/env/AWS_ACCESS_KEY_ID 2>/dev/null)}"
$ direnv allow
```

<details>
<summary><strong>Why should <code>.envrc</code> prefer the ambient variable first?</strong></summary>

The same project usually runs in more than one place — your machine, a
teammate's machine, and CI/CD or a container. Each gets its credentials
differently: **in CI/CD or a container**, the platform itself injects a
secret directly as an environment variable — there's no
`~/.config/workspaces-host/credentials` file there at all. **On your
machine**, in this sandbox, that variable is deliberately *not* already
set in your shell — it's sitting in the file above instead, waiting for a
project's `.envrc` to read it.

So a `.envrc` that works everywhere must **prefer whatever's already in
the environment, and only fall back to your local sandbox's file** —
never the other way around, since overwriting a value CI/CD already
injected would silently use the wrong credential in the one place that
had the right one configured. Shell's `${VAR:-fallback}` does exactly
this in one line, as shown above: in CI/CD the `cat` never even runs
(the pipeline's own secret wins); on your machine, nothing set it yet, so
it falls through to the file.

</details>

### Advanced: encrypting a secret at rest with sops

The credentials file above is protected by ordinary file permissions —
the right default for a personal, single-user sandbox. If you specifically
want field-level *encryption at rest* for one credential, `home/secrets.nix`
exposes an opt-in `workspacesHost.secrets` option (`age`/`sops`), decrypted
at activation time into the same
`~/.local/state/workspaces-host/secrets/env/` location the plain
credentials file writes to — both mechanisms feed the same place, so pick
whichever one secret needs the extra step and leave the rest in the
simple file. See `home/secrets.nix` for the exact option shape.

### Keeping credentials out of git history

- Keep `.env` and any real credential file in your *project's own*
  `.gitignore` (not this repository's).
- Before committing, check what's actually staged (`git diff --staged`),
  especially after a broad `git add`. `gitleaks` is installed and ready
  to scan a repo for anything that looks like a secret:
  ```console
  $ gitleaks detect --source . -v
  ```
- Get a short-lived token from GitHub/GitLab instead of a permanent one,
  and rotate it the same way, per above.

### Setting up AI harness credentials

Every profile installs `nodejs` (needed by every AI CLI below) and `aider-chat` — provider-agnostic,
so it works with whichever API key you have, already on `PATH`, nothing to install. The fast-moving
hosted CLIs below aren't packaged in this flake's pinned nixpkgs — install them with their own
`npm install -g`, same as upstream documents:

```console
$ npm install -g @anthropic-ai/claude-code   # provides: claude
$ npm install -g @openai/codex               # provides: codex
$ npm install -g @google/gemini-cli          # provides: gemini
$ gh extension install github/gh-copilot     # GitHub Copilot CLI, via gh
```

<details>
<summary><strong>Why aren't Claude Code/Codex/Gemini CLI packaged in Nix like everything else?</strong></summary>

They ship near-weekly releases, and hand-vendoring each one as a Nix derivation would mean either
pinning to a stale version indefinitely or re-deriving a new hash on every release - a maintenance
burden this repo isn't taking on for tools whose whole value is being current. `nodejs` (their
shared runtime) is provisioned declaratively instead, so installing the actual CLI is just the one
`npm install -g` command upstream already documents.

</details>

`doctor` checks whether each is installed and whether it has a key to
use. Give one its key by adding it to
`~/.config/workspaces-host/credentials` (above) and running
`workspaces-host-update`:

```dotenv
ANTHROPIC_API_KEY=sk-ant-yourRealKey
```

<details>
<summary><strong>Why per-invocation credential scoping instead of exporting the key?</strong></summary>

`claude`/`codex`/`gemini`/`aider`/`gh`/`glab` each get their own bash function of the same name
(`home/ai-harness.nix`) that looks for their matching key and sets it only for that one
invocation - not a shell-wide `export`. This is Constitution Principle III applied literally: a
secret is resolved "at the point of use," never as an ambient variable available to the whole
shell session (and everything else running in it, an AI coding agent included). Run `claude`
afterward and its wrapper finds the value, sets `$ANTHROPIC_API_KEY` only for that one call, and
never touches the rest of your shell - `echo $ANTHROPIC_API_KEY` in the same window stays empty.
If a CLI supports its own browser-based `login` command instead (Claude Code and Gemini CLI both
do), that works too - the wrapper is a transparent no-op when no matching credential is
configured, and `doctor` only warns if neither a configured credential nor an existing login is
present.

</details>

That's everything you need to get started. Every section below covers an additional capability —
read them whenever you're ready, or jump straight to whichever one you need.

<details>
<summary><strong>Why this exists</strong></summary>

The point isn't just "a nice shell" — it's that a human engineer, a teammate who's new to Linux, a
CI/CD pipeline, and an AI coding agent (Claude Code, Codex, an autonomous CI bot, ...) can all open
a terminal on completely different machines and find the *exact same* structure: the same place
repos get cloned to (`~/workspaces`, managed by `ws-repos`), the same command to check the
environment (`doctor`), the same command to update it (`workspaces-host-update`), the same shell,
the same tools, at the same versions. When everyone and everything working on a project — across
engineering, DevOps, and an AI agent doing a chunk of the work overnight — shares one predictable
layout, nobody (human or machine) has to re-learn "how this particular person's/pipeline's machine
happens to be set up" before they can be useful on it.

That matters more, not less, now that AI has put a real command line within reach of people who
never expected to need one. Effectively everyone is an engineer now, at least some of the time —
and everyone doing that work deserves the same consistent, good-looking, fully capable Linux
environment, not a stripped-down or inconsistent one just because they're newer to it. On Windows,
WSL already gives you the Windows desktop, files, and apps you know; `workspaces-host` is what
gives the Linux side of that the same consistent, ready-to-go engineering setup everyone else on
the team has — so the "new to Linux" part is the only unfamiliar piece, not the tooling itself.

This is also why AI CLIs are provisioned as part of the standard environment (see "Setting up AI
harness credentials" above): once an engineer — technical or not — has an API key configured the
safe way this repo documents, they can point an AI harness at their own sandbox and ask it to help
configure or improve their setup, the same way it would help with application code. That's a
deliberate design goal, not an accident: lowering the barrier to actually using and improving a
real engineering environment is the whole point.

But that consistency is the thing to protect. If an AI harness (or a person) comes up with a
genuinely good improvement while working in one sandbox — a new tool, a better default, an extra
`doctor` check, a smarter install step — the right place for it is **this repository, via a pull
request**, not just that one person's credentials file or a one-off tweak that only exists on
their machine. Your credentials file (see "Setting up your credentials" above) exists for things
that are genuinely personal — your name, your API keys — precisely so that everything else stays
shared and in sync across the whole team. A good idea that only lives in one sandbox helps one
person; the same idea merged back here helps everyone (and every CI run, and every agent) who uses
this setup after that.

</details>

Every spec under [`specs/`](specs/) (001 through 017) is implemented: the flake/shell base,
credentials (including GitHub/GitLab tokens), `ws-repos`, `doctor`/rollback, container parity,
compliance/observability tooling, the Java/Postgres toolchain, AI coding agent harness
credentials, Nerd Font/prompt polish, agent-harness project scaffolding, bulk git tooling, secrets
backup/restore, advanced `local.nix` overrides, per-persona workspace profiles (the base profile
stays deliberately small — see "Workspace profiles" below for what moved behind a persona), a
handful of everyday utilities, and Git hooks and zero-trust networking clients (Lefthook,
Tailscale/Nebula). See each spec's `spec.md` for its exact requirements.

## Your shell

This setup uses **bash**, not a different shell — on purpose: it's what
every tutorial and every other Linux/WSL machine already assumes, so
nothing you copy-paste needs translating first. Plain bash on its own is
missing a few things other shells are known for, so those are added on
top:

- **Syntax highlighting and autosuggestions as you type**
  ([`ble.sh`](https://github.com/akinomyoga/ble.sh)) — press `→` or `End`
  to accept a suggestion.
- **Fuzzy history and file search** ([`fzf`](https://github.com/junegunn/fzf)) —
  `Ctrl+R` fuzzy-searches history, `Ctrl+T` fuzzy-finds a file, `Alt+C`
  fuzzy-finds and `cd`s into a directory. All three use `fd`, so they skip
  `.git`/build output automatically.
- **Smarter directory jumping** ([`zoxide`](https://github.com/ajeetdsouza/zoxide)) —
  `z <part of a path>` jumps there by frecency; `zi` picks fuzzily among
  matches. A separate command, not a replacement for `cd`.
- **oh-my-posh**, with its own upgrade nag turned off (see below).

<details>
<summary><strong>Modern replacements for everyday CLI tools</strong> (optional — everything below still works under its own name)</summary>

| Instead of | Try | What's different |
| --- | --- | --- |
| `ls` | `eza` | colorized, git-status-aware, tree view (`eza --tree`) |
| `cat` | `bat` | syntax highlighting, git diff markers in the margin |
| `grep` | `rg` (ripgrep) | much faster, skips `.gitignore`d files automatically |
| `find` | `fd` | simpler syntax, faster, also skips `.gitignore`d files |
| `git diff`/`log -p` | (automatic) | `delta` is already wired in as git's pager |

`ll`/`ls` are aliased to `eza`, and `cat` is aliased to `bat --paging=never`
— everything else is left alone under its own name, since a different
enough flag set would break muscle memory more than help.

</details>

<details>
<summary><strong>Why not <code>oh-my-posh enable autoupgrade</code>?</strong></summary>

It might seem like the obvious fix for the "a new release is available" message — but
oh-my-posh's own binary lives in the read-only Nix store, so a self-upgrade would either fail
outright, or (worse) succeed by writing a new binary somewhere Nix has no record of - directly
undermining the one guarantee this repository exists to provide (every tool pinned by a lockfile,
not resolved against a mutable upstream at runtime). The message is silenced correctly instead
(`disable_notice` in `home/shell.nix`) - a cosmetic setting, not a version change. Want a newer
oh-my-posh? That's a nixpkgs pin bump in this flake, the same as updating any other tool.

</details>

<details>
<summary><strong>Fonts for the prompt icons</strong> (optional — the prompt works fine without them, just with a few boxes/<code>?</code>s where icons would be)</summary>

The prompt uses small icons (branch name, folder, a clock, ...) from a
"Nerd Font" - a regular monospace font with extra symbols added. Every
profile installs the font file itself (`home/fonts.nix`); this step is
about telling your actual terminal window to use it, which is a setting
in the terminal app itself, not something Nix can turn on for you.

- **Check the font is actually there** first: `fc-list | grep "JetBrainsMono Nerd Font Mono"` should print several `.ttf` paths.
- **The exact font name to pick**: `JetBrainsMono Nerd Font Mono` (also shown as `JetBrainsMono NFM`). Use the **Mono** variant specifically.
- **On Windows (Windows Terminal)**: the font needs to be installed on the **Windows side** too. Download `JetBrainsMono.zip` from the [Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases), install the `.ttf` files, then Windows Terminal → Settings → Profiles → Debian → Appearance → Font face → `JetBrainsMono NFM`.
- **On Linux with GNOME Terminal**: Terminal → Preferences → your profile → Text → uncheck "Use the system fixed-width font" → Custom font → `JetBrainsMono Nerd Font Mono`.
- **Any other terminal app** (kitty, Alacritty, Konsole, iTerm2, ...): the font is already installed and discoverable system-wide — just set that app's own font setting to the same name.
- **Check it worked**: close and reopen your terminal window and look at your prompt — actual icons, not boxes or `?` marks.

</details>

## Managing your repos (`ws-repos`)

Keep every project you work on under one predictable layout:

```console
$ nano ~/workspaces/ws-repos.json   # { "repos": [{ "repo": "github.com/org/repo" }] }
$ ws-repos ensure                    # clone-or-pull everything listed
$ ws-repos status                    # dirty/untracked/ahead/behind/locked/stash/clean, across every repo
$ ws-repos inspect                   # list git hosts and repos referenced by *.mgit.code-workspace files
```

Every repo lives at `~/workspaces/<git-host>/<org>/.../<repo>` — the same
path segments as its HTTPS clone URL, so the layout is predictable and
greppable no matter how many hosts/orgs you work across. `ws-repos ensure`
also follows `*.mgit.code-workspace` files (VS Code multi-root workspaces)
inside a repo, symlinking them to `~/workspaces` and recursively ensuring
whatever repos they reference — several independent repos, potentially
from different hosts, presenting as one composed "workspace" with no
submodules and no vendoring.

<details>
<summary><strong>Why is this called <code>ws-repos</code> and not <code>mgit</code>, and why does the file suffix still say ".mgit"?</strong></summary>

This is a POSIX-shell port of the "mGit" pattern from
[strategy-coach/workspaces](https://github.com/strategy-coach/workspaces) (`mgit.ts`/
`ws-ensure.ts`): the same governed directory convention, the same idempotent clone-or-pull
semantics, and the same VS Code multi-root composition trick. Two things are named differently
from upstream, deliberately:

- **The command is `ws-repos`, not `mgit`.** Unrelated third-party tools are also named `mgit`;
  naming this command differently avoids that collision entirely. It's a naming choice only - the
  directory convention and file-matching behavior are unchanged.
- **The workspace file suffix stays `*.mgit.code-workspace`.** That string comes from upstream
  `mgit.ts`'s own hardcoded matcher, not from this tool's name - keeping it means a
  `*.mgit.code-workspace` file written for the original mGit tooling (or for v2's own `mgit`) is
  still recognized here unchanged.

This revision also brought `ws-repos status` back up to upstream's own fidelity: it now reports a
stuck `index.lock` ("locked") and stash count, and separates "untracked" from "dirty" the way
upstream's `mGitStatus()` does - a prior port had simplified these away. Parsing a
`*.mgit.code-workspace` file also now tolerates the comments VS Code itself allows there (a
best-effort filter for `//` and `/* */` comments, not a full JSONC parser - see spec 003's
Assumptions for the one edge case this doesn't cover).

</details>

**On WSL, this also matters for speed, not just organization** — see the
`/mnt` note in the Windows/WSL section above. `doctor` checks this for
both `$HOME` and wherever you're currently standing.

See spec 003 for the full `ws-repos` requirements.

### Bulk changes across many repos, and other git helpers

`ws-repos` (above) governs *which* repos land under `~/workspaces`. `git-xargs`
([gruntwork-io/git-xargs](https://github.com/gruntwork-io/git-xargs)) is in every profile too —
run a command, or a small Go callback, against many GitHub repos in one shot and open a PR with
the results in each:

```console
$ git-xargs --repos repo1,repo2,repo3 --branch-name my-fix --commit-message "my fix" -- ./my-script.sh
```

A few more everyday multi-repo git helpers live in the `agent-ops` persona (see "Workspace
profiles" below) rather than every profile, since they're specialized enough that most engineers
won't reach for them on day one:

- **`git-extras`** — a grab-bag of everyday `git <cmd>` subcommands
  (`git summary`, `git changelog`, `git effort`, `git delete-merged-branches`, ...).
- **`semtag`** — compute (and optionally apply) the next semantic version
  git tag: `semtag current`, `semtag final -s minor -a`.
- **`git-standup`** — list your commits since your last working day,
  across one or more repos, for daily standups.

## Checking your environment (`doctor`) and rolling back

```console
$ doctor
```

Prints one `PASS`/`WARN`/`FAIL` line per check and exits non-zero only if something actually
failed. By default it shows only the essentials — did the install actually work: Nix/flakes,
home-manager, the shell/prompt/direnv, git and its identity, the credentials file, GitHub/GitLab
authentication, and `ws-repos` — plus a one-line summary count. Run `doctor --all` for everything
else too: common WSL/SSH/disk/locale pitfalls, the AI harness CLIs, every ported tool, and every
persona-specific check (compliance, backend, agent-ops, networking) reported as an informational
`WARN` if that persona isn't active. A real problem is never hidden by the terse default — a
genuine `FAIL` always prints, in either mode.

If an update ever breaks something, roll back with home-manager's own generation mechanism — no
separate tooling needed. Every `workspaces-host-update`/`home-manager switch` creates a new,
numbered generation rather than editing anything in place, so the previous one is always still
there to go back to:

```console
$ home-manager generations
2026-09-13 14:02 : id 6 -> /nix/store/i9k2x...-home-manager-generation   # the broken one
2026-09-13 09:47 : id 5 -> /nix/store/7fa31...-home-manager-generation   # the one before it
$ /nix/store/7fa31...-home-manager-generation/activate   # re-run that generation's own activate script
```

That's it — your environment is back to exactly how it was at generation 5, with nothing to
reinstall.

## Keeping your sandbox in sync

New features and fixes land on `main` as small, independent, merged
changes. Your machine doesn't pick those up by itself:

```console
$ cd ~/.workspaces-host-v3   # or wherever $WORKSPACES_HOST_REPO points
$ workspaces-host-update      # pulls, re-applies your credentials, re-activates, runs doctor
```

Every interactive shell also checks, once a day in the background (never
blocking shell startup, silently skipped with no network), whether
`$WORKSPACES_HOST_REPO`'s `origin/main` has moved — informational only, it
never runs the update for you:

```text
workspaces-host-v3: 3 commit(s) behind origin/main - run workspaces-host-update to pick up new features
```

## Workspace profiles (personas)

The base profile (`current`/`default`) is deliberately small — just what every engineer needs on
day one. For a specialized set of extra tools on top of it, activate a persona instead (spec 014):

```console
$ nix build ".#homeConfigurations.current-backend.activationPackage" --impure     # Java+Maven, postgresql/pgpass, redis, docker-compose, httpie
$ nix build ".#homeConfigurations.current-data.activationPackage" --impure        # python3, uv, duckdb
$ nix build ".#homeConfigurations.current-mobile.activationPackage" --impure      # android-tools (adb/fastboot), watchman
$ nix build ".#homeConfigurations.current-agent-ops.activationPackage" --impure   # act, semtag/git-standup/git-extras, gopass, deno, llm
$ nix build ".#homeConfigurations.current-compliance.activationPackage" --impure  # osquery, cnquery, steampipe, openobserve, surveilr
$ nix build ".#homeConfigurations.current-networking.activationPackage" --impure  # tailscale, nebula
$ ./result/activate
```

Personas are strictly additive — everything the base profile gives you is still there, plus that
persona's extra packages. Activating none of them (the default) is completely unaffected, and
`doctor` (below) reports every persona-specific tool as an informational `WARN`, not a problem,
when its persona isn't active.

## More everyday tools

A couple of small, general-purpose utilities round out the base profile (spec 015):

- **`wget`**, **`rclone`** — a plain HTTP fetcher, and a directly-runnable `rclone` (not just the
  copy `sensitivectl` uses internally — see "Backing up sensitive local directories" below).
- **`git-chglog`** — generate a `CHANGELOG.md` from your commit history.
- **SSH agent auto-start** — a new login shell automatically starts an SSH agent and loads
  `~/.ssh/id_ed25519` or `~/.ssh/id_rsa` (whichever exists) if nothing's loaded yet — no more
  manual `ssh-agent`/`ssh-add` per session.
- **`cdp`** — an alias that `cd`s to the current git repository's top-level directory.

`gopass` (general secrets management) and `deno` (a general-purpose scripting runtime, with
`deno-run`/`deno-test` aliases) are in the `agent-ops` persona instead of every profile — see
"Workspace profiles" above.

<details>
<summary><strong>Why is Deno available at all when this repo's own tools no longer need it?</strong></summary>

v1 (the original chezmoi-based repo) called Deno "a core requirement," and used it for `ws-repos`'
own upstream ancestor (`mgit.ts`) plus most of its custom tooling. v2 reimplemented those specific
scripts in POSIX `sh` to avoid *this repository's own tooling* needing a Deno dependency - but that
sidestepped, rather than answered, a separate question: should engineers still have Deno available
as a general scripting runtime? v1's answer was yes (it recommends `deno`+`dax` over `make` for
custom task running); this repo agrees, so Deno is provisioned as a plain tool, independent of what
`ws-repos`/`doctor` are written in - just not to every profile by default, since it's still a
specialized choice most engineers won't reach for on day one (a newbie-simplification pass moved
it to the `agent-ops` persona).

</details>

## Git hooks (`lefthook`)

Every profile installs [Lefthook](https://lefthook.dev/). Adopt it in any project with two
commands:

```console
$ cp ~/.workspaces-host-v3/templates/lefthook.yml.example ./lefthook.yml   # then edit the placeholder commands
$ lefthook install
```

See [`templates/lefthook.yml.example`](templates/lefthook.yml.example) for a starter covering
`pre-commit` and `pre-push`.

<details>
<summary><strong>Why wasn't this here before?</strong></summary>

v1's own README carried this as an unchecked roadmap item ("Integrate Lefthook Git hooks
manager...") that v1 itself never built. It turned out to be a clean fit once actually attempted:
install the tool declaratively via Nix (replacing v1's proposed `brew install`), and provide a
documented, copy-in example config rather than forcing hooks on every repo.

</details>

## Zero-trust networking (optional persona)

The `networking` persona (see "Workspace profiles" above) installs the
[Tailscale](https://tailscale.com/) and [Nebula](https://github.com/slackhq/nebula) mesh VPN
clients — no service, no auto-start, no key material provisioned; joining either is always an
explicit step you take yourself:

```console
$ nix build ".#homeConfigurations.current-networking.activationPackage" --impure && ./result/activate
$ sudo tailscale up      # interactive login against your own Tailscale account
$ nebula -config nebula.yml   # needs a certificate issued by your mesh's own CA/admin first
```

`doctor --all` reports both clients, informationally — neither is required for anything else in
this repository, and most engineers never need this persona at all.

<details>
<summary><strong>Why does this repo install the clients but never configure or auto-start them?</strong></summary>

This was another item on v1's own unfinished roadmap ("Integrate Zero Trust client
infrastructure starting with Tailscale... and then add Nebula..."). Nix can provision the
*clients* declaratively the same as every other tool here - but joining an actual mesh (a
Tailscale account and its login flow, or a Nebula CA certificate issued by a network admin) is
unavoidably a human, out-of-band action, the same category as a git identity or an API key
(Constitution Principle III's "provisioning the key is a deliberate, separate, human action"
applies equally to network trust material). Standing up a server-side control plane (a
self-hosted Headscale instance, a Nebula lighthouse) is infrastructure operators choose to run
separately - entirely out of scope for one engineer's sandbox.

</details>

## Container & cloud-harness parity

```console
$ nix build .#oci-image             # same shell/tools/dotfiles as the host profile
$ docker load < result
$ docker run -it workspaces-host:latest

$ nix build .#oci-image-sandboxed   # + a default-deny network egress allowlist, non-root user
$ docker load < result
$ docker run -it --cap-add=NET_ADMIN --cap-add=NET_RAW workspaces-host-sandboxed:latest
```

The sandboxed image runs `init-firewall` as root, self-verifies the
allowlist, then drops to a non-root `agent` user before handing off to the
workload. Set `FIREWALL_ALLOWED_DOMAINS` to override the default
allowlist, or `SKIP_FIREWALL=1` as an explicit opt-out on a runtime that
can't grant `NET_ADMIN`. See spec 005 for details.

## Compliance & observability tooling (optional persona)

This sandbox includes tooling for auditing itself — useful for SOC2 and similar compliance
requirements, or just for understanding what's actually running on the machine. It's specialized
enough that it lives in the `compliance` persona (see "Workspace profiles" above) rather than
every profile — activate it, and you get all five with nothing extra to opt into (spec 006):

```console
$ nix build ".#homeConfigurations.current-compliance.activationPackage" --impure && ./result/activate
```

- **`osqueryi`** (interactive) / `osqueryd` (daemon) — SQL-queryable
  operating-system instrumentation. Linux-only (nixpkgs); `doctor` reports
  this as an informational WARN, not a FAIL, on Darwin.
- **`cnquery`** — Mondoo's cloud-native, graph-based asset inventory query
  tool, across cloud/Kubernetes/API resources too, not just the local host.
- **`steampipe`** — queries cloud, code, and log sources with plain SQL.
- **`openobserve`** — a self-hostable logs/metrics/traces backend; a
  binary on `PATH`, not a running service — start it yourself when you
  actually want to ingest and query telemetry.
- **`surveilr`** — walks files/databases/APIs and resource-surveils them
  into a local SQLite database. Upstream only publishes `x86_64` release
  binaries for Linux and Darwin; `doctor` reports its absence elsewhere as
  an informational WARN.

None of these run anything by default — they're audit/query tools you reach for, not background
daemons this repository starts for you.

## PostgreSQL credentials (`~/.pgpass`, `~/.psqlrc`, `pgpass`) (optional persona: `backend`)

The `backend` persona (see "Workspace profiles" above) ships `~/.psqlrc` (a full `psql` client
config — colored prompt, sane defaults, admin queries like `settings`, `locks`, `dbsize`) and
bootstraps an empty `~/.pgpass` (mode 600) on first activation (spec 007). Add connections using a
small comment-header convention:

```console
$ cat >> ~/.pgpass <<'EOF'
# { id: "MYDB", description: "Purpose", boundary: "Network" }
localhost:5432:mydb:myuser:mypassword
EOF
```

Then look connections up by `id`:

```console
$ pgpass ls                                    # list every connection's id/description/host
$ pgpass test                                  # validate the file, reporting any parse issues
$ eval "$(pgpass env --conn-id=MYDB)"          # export PGHOST/PGPORT/PGDATABASE/PGUSER/PGPASSWORD
$ eval "$(pgpass psql --conn-id=MYDB)"         # runs "psql -h ... -p ... -d ... -U ..." for MYDB
$ pgpass url --conn-id=MYDB                    # postgres://user:pass@host:port/db
```

`--conn-id` takes an extended regex, so `--conn-id=".*"` matches every
connection.

## Java toolchain (optional persona: `backend`)

The `backend` persona (see "Workspace profiles" above) installs a JDK (`java`) and Maven (`mvn`),
with `JAVA_HOME` already set — no separate version manager needed (spec 007).

<details>
<summary><strong>Why not SDKMAN! or another Java version manager?</strong></summary>

Nix itself already pins reproducible versions for every tool in this setup, Java included, so a
second version manager on top of it would just duplicate that job. Override `home/java.nix`'s
`pkgs.jdk`/`pkgs.maven` in a fork for a different JDK version or vendor.

</details>

## Scaffolding a project for an AI coding agent

`scaffold-agent-harness` (spec 010) copies a fixed template
(`AGENTS.md`, `.mcp.json`, `.claude/settings.json` + a `SessionStart`
hook, `.claude/skills/README.md`) into a project directory, never
overwriting a file that's already there:

```console
$ cd your-project
$ scaffold-agent-harness
```

Every profile also installs `specify` ([GitHub Spec Kit](https://github.com/github/spec-kit))
and `backlog` ([Backlog.md](https://github.com/MrLesk/Backlog.md)), so a
scaffolded project can start spec-driven, task-tracked work immediately —
`specify init` populates `.claude/skills/speckit-*` in the template's
empty skills directory.

## Backing up sensitive local directories (`sensitivectl`)

For a local directory of genuinely sensitive material you want synced to
your own remote storage — not the credentials file, which is handled
above — `sensitivectl` (spec 012) backs it up to, and restores it from,
any `rclone`-supported remote:

```console
$ cat ~/.config/workspaces-host/sensitivectl.json
{ "profiles": { "notes": { "local": "/home/me/Sensitive", "remote": "myremote:backups/sensitive" } } }
$ sensitivectl backup notes
$ sensitivectl restore notes
```

Anything after `--` is passed straight through to the underlying `rclone
sync` (e.g. `-- --dry-run`). `rclone` itself is configured with your
remote's credentials out-of-band (`rclone config`) — this repo doesn't
manage that.

## Advanced: personal Nix-level overrides (`local.nix`)

Most people never need this — the credentials file (above) is the
recommended way to customize identity and tokens. For a genuinely
Nix-level personal tweak (an extra package, a `workspacesHost.secrets`
declaration) that a fork/PR isn't the right fit for, copy
`local.nix.example` to `~/.config/workspaces-host/local.nix` (spec 013).
Only the `current` profile picks it up — `default` and every other
fixed-identity profile `nix flake check` builds are completely
unaffected by its presence or absence, so it's always safe to have one.

## Development

This repository follows [GitHub Spec Kit](https://github.com/github/spec-kit)'s
spec-driven workflow: every feature has a spec, a plan, and (once
implemented) code, under `specs/<NNN-name>/`. See
[`.specify/memory/constitution.md`](.specify/memory/constitution.md) for
the non-negotiable principles, and run `nix flake check` before sending a
change. A spec that no longer matches the code is worse than no spec — a
follow-up fix updates that feature's own spec in the same change, not as
a separate cleanup pass that may never happen.
