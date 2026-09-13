# workspaces-host-v3

I built this so you get one working engineering setup, everywhere: a configured bash shell, git
and GitHub/GitLab credentials handled safely, a way to keep every git repo you touch in one
predictable place, and a growing set of everyday developer tools. Same setup on Windows (via
WSL), Linux, a Mac, inside a container, or in a cloud AI-agent session. One command gets you
there.

It runs on Nix flakes and home-manager. The whole environment is code, not a list of manual steps
someone forgot to update. Pull a commit, rebuild, and you get the exact same result every time.
Updating later is a `git pull` plus one command (see "Keeping your sandbox in sync" below).

The principles behind these choices live in
[`.specify/memory/constitution.md`](.specify/memory/constitution.md); the requirements each
feature implements live in [`specs/`](specs/).

## Installation

<details>
<summary><strong>New to Nix? Here's what's actually happening, in three sentences</strong></summary>

Nix is a package manager that installs exact, pinned versions of every tool, bash and git
included, into its own isolated store instead of whatever versions your OS happens to ship. A
flake is just this repo's own description, in one file (`flake.nix`), of exactly which tools and
settings make up your environment. home-manager applies that description to your account, and
every time it does, it creates a new generation, a full numbered snapshot you can switch back to
instantly (see "rolling back" below) instead of editing your files in place. That's all you need
to know to use everything below.

</details>

On Windows? Start here, that's most people reading this. Already on Linux or a Mac? Skip to
"Other platforms."

### Windows (via WSL): start here

WSL runs a real Linux system next to your normal Windows apps. Everything below happens inside
that Linux system, a window titled "Debian," except step 1.

1. Open PowerShell as Administrator. Run:
   ```powershell
   wsl --install -d Debian
   ```
   This may ask you to restart your computer.
2. Open "Debian" from the Start menu. The first time it opens, pick a Linux username and
   password. Use a different password than your Windows login.
3. From inside that Debian window, run this one line:
   ```console
   $ cd && sudo apt-get update && sudo apt-get install -y curl git && sh -c "$(curl -fsSL https://raw.githubusercontent.com/intellectual-frontiers/workspaces-host-v3/main/install.sh)"
   ```
   The `cd` gets you out of the `sudo` asks for the password from step 2. That's the only password prompt in the whole
   process. It takes a few minutes the first time. Run it again later and it just skips what's
   already done and updates the rest; that's what `workspaces-host-update` does under the hood
   once you're set up.

   <details>
   <summary><strong>Why start with <code>apt-get install curl git</code>?</strong></summary>

   A fresh Debian/WSL image doesn't ship `curl`. A one-liner that starts with
   `curl -fsSL https://.../install.sh` can't fetch itself on a machine with no `curl`. So this
   installs just enough, `curl` and `git`, to fetch and run the real installer, which handles
   everything else itself, Nix's own `xz` dependency included.

   </details>

4. Fill in your credentials and apply them:
   ```console
   $ nano ~/.config/workspaces-host/credentials
   $ workspaces-host-update
   ```
   `workspaces-host-update` applies your changes and finishes by running `doctor`, so you get a
   `PASS`/`WARN`/`FAIL` line for everything in the same command. A `WARN` for anything you left
   blank is normal.

That's it. Close this window and open a new one; step 3 already set your login shell, but this
window is still running whatever you started in. Look for the new prompt and autosuggestions as
you type. That's your confirmation it worked.

If a new window looks the same as the old one, step 3's automatic `chsh` probably failed: a
locked-down `/etc`, no `sudo`, something like that. `doctor` will tell you, with the exact command
to fix it.

<details>
<summary><strong>Why keep repos under <code>~/workspaces</code>, not <code>/mnt/c/Users/...</code>?</strong></summary>

WSL can read Windows files and Windows can read WSL files, but crossing that boundary is slow,
git especially. That's exactly what WSL's "I/O intensive operation like git" warning is telling
you. `doctor` checks for this too, both for `$HOME` and wherever you're standing. See "Managing
your repos" below for the tool that keeps every repo under `~/workspaces` automatically.

</details>

### Using VS Code with this setup (WSL)

I don't install VS Code here. If `code .` from your Debian window opens the Windows copy of VS
Code, or errors out, that's WSL working as designed. Microsoft's supported way to edit WSL files
in VS Code is to let it do exactly that:

1. Install VS Code on Windows, not inside Debian: [code.visualstudio.com](https://code.visualstudio.com/).
2. Install the "WSL" extension in that Windows VS Code, the one Microsoft publishes.
3. From your Debian window, in any project folder, run `code .`. The first time, this installs a
   small VS Code Server inside WSL (it needs network access and takes a minute), then opens a
   normal VS Code window. Editing, the terminal, every extension: all of it runs inside Linux,
   even though the window itself is a Windows application.

If step 3 fails after you've installed the extension, it's almost always the VS Code Server
install. Run `code --version` from inside WSL to check whether it landed. Closing and reopening
the Debian window, which gives you a fresh `$PATH`, fixes most of these.

### Other platforms (Linux or macOS, no WSL)

Open a regular terminal. Nothing WSL-specific applies. The only thing that differs by platform is
how you get `curl`/`git` (and Nix's `xz` dependency) onto the system in the first place, since
`install.sh` can't run until something has fetched it:

- **Linux (a VM, or a real machine)**: most VM/cloud images already have `curl`/`git`/`xz`. A
  bare-bones one won't, same gap as fresh WSL/Debian above. If `curl -V` says "command not
  found," install them yourself first: `sudo apt-get install -y curl git xz-utils`
  (Debian/Ubuntu), `sudo dnf install -y curl git xz` (RHEL/Fedora/CentOS), or `sudo pacman -Sy
  --noconfirm curl git xz` (Arch). Then run the same one-liner as step 3 above, minus the
  `apt-get install` prefix; that part was WSL/Debian-specific. `install.sh` auto-detects which of
  those three families you're on for anything else it needs. Want to build or run this repo's
  container images too? Install Docker: `sudo apt install -y docker.io` (Debian/Ubuntu; see
  [docs.docker.com](https://docs.docker.com/engine/install/) for other distros).
- **macOS**: `curl`, `git`, and `xz` are already there, Apple ships all three. Run the plain
  one-liner from step 3, no `apt-get`/`dnf`/`pacman` prefix, Apple Silicon or Intel; it senses
  your system automatically (`current` handles that). Container sandboxing (spec 005's
  network-restricted image) doesn't run on macOS; everything else does.
- **A Linux distro `install.sh` doesn't recognize**: it says so and exits without touching
  anything. Install `curl`/`git`/`xz` yourself, then re-run it. Everything after that is
  distro-agnostic.

Windows without WSL doesn't work. Nix needs a real Linux or macOS system underneath it, and WSL is
exactly that, so it's the only path on Windows.

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

`install.sh` is the real source of truth for these steps. It's plain, readable shell, worth a
skim before you pipe anything into a shell either way.

## Setting up your credentials

Your git name/email and your GitHub/GitLab tokens go in one plain text file, outside this repo
entirely: `~/.config/workspaces-host/credentials`. `KEY=value` lines, nothing more. No Nix syntax,
no encryption tool to learn first. `workspaces-host-update` creates a blank one the first time you
run it.

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

That one command re-applies your setup with the new values and runs `doctor` right after, so you
see immediately whether it worked.

<details>
<summary><strong>Why a plain file outside the repo, instead of Nix or an encrypted store?</strong></summary>

Three reasons.

It never leaves your machine. It lives outside this repo, so `git pull`/`workspaces-host-update`
can't touch it, overwrite it, or conflict with it, and there's nothing here you could accidentally
commit.

It's protected the way `~/.ssh` or `~/.aws/credentials` are. `workspaces-host-update` sets it to
mode 600 every time it runs and fixes the permissions if anything loosens them. `doctor` checks
this too.

It's read by a plain script, not by Nix. `workspaces-host-update` parses it as `KEY=value` text.
It never `source`s it as a shell script, so a stray backtick or `$(...)` in a token can't run as a
command. It writes your git name/email into a file git itself reads automatically, and drops
every other token into a per-command-scoped mechanism: a key is only ever visible to the one
command that needs it, `gh`/`glab`, or an AI harness CLI (see "Setting up AI harness credentials"
below), never the rest of your shell.

This is the simplest thing that satisfies Constitution Principle III, secrets never touch the
agent's shell unscoped, for the common case. No `age`/`sops` steps just to set your name and
email. The advanced sops-based path below is for what this doesn't cover.

</details>

**Rotating a token**: edit the line, run `workspaces-host-update` again. No encrypted file to
regenerate, no old plaintext left behind.

**Need a credential this file doesn't have a line for** (a cloud provider token, a
project-specific API key)? Add it with whatever name makes sense, `AWS_ACCESS_KEY_ID=...` say.
`workspaces-host-update` writes every line that isn't `GIT_NAME`/`GIT_EMAIL` into
`~/.local/state/workspaces-host/secrets/env/<NAME>`, ready for a project's own `.envrc`:

```console
$ cat .envrc
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-$(cat ~/.local/state/workspaces-host/secrets/env/AWS_ACCESS_KEY_ID 2>/dev/null)}"
$ direnv allow
```

<details>
<summary><strong>Why should <code>.envrc</code> check the ambient variable first?</strong></summary>

The same project runs in more than one place: your machine, a teammate's machine, CI/CD, a
container. Each gets its credentials differently. In CI/CD or a container, the platform injects
the secret straight into the environment; there's no credentials file there at all. On your
machine, in this sandbox, that variable is deliberately not set in your shell already. It's
sitting in the file above, waiting for `.envrc` to read it.

So a `.envrc` that works everywhere has to check the environment first and only fall back to your
sandbox's file, never the other way around. Get that order wrong and you'd silently overwrite the
credential CI/CD already injected with the wrong one. `${VAR:-fallback}` does exactly this in one
line: in CI/CD the `cat` never runs, because the pipeline's secret already won; on your machine,
nothing set it yet, so it falls through to the file.

</details>

### Advanced: encrypting a secret at rest with sops

The credentials file above is protected by ordinary file permissions. That's the right default
for a personal, single-user sandbox. If you actually want field-level encryption at rest for one
credential, `home/secrets.nix` exposes an opt-in `workspacesHost.secrets` option (`age`/`sops`),
decrypted at activation time into the same `~/.local/state/workspaces-host/secrets/env/` location
the plain credentials file writes to. Both mechanisms feed the same place, so pick whichever one a
given secret needs and leave the rest in the simple file. See `home/secrets.nix` for the option
shape.

### Keeping credentials out of git history

- Keep `.env` and any real credential file in your *project's* `.gitignore`, not this repo's.
- Check what's actually staged before you commit (`git diff --staged`), especially after a broad
  `git add`. `gitleaks` is already installed:
  ```console
  $ gitleaks detect --source . -v
  ```
- Use a short-lived token from GitHub/GitLab instead of a permanent one, and rotate it the same
  way as above.

### Setting up AI harness credentials

Every profile installs `nodejs` (every AI CLI below needs it) and `aider-chat`, provider-agnostic,
works with whatever key you have, already on `PATH`. The fast-moving hosted CLIs below aren't
packaged in this flake's pinned nixpkgs; install them with their own `npm install -g`, same as
upstream tells you to:

```console
$ npm install -g @anthropic-ai/claude-code   # provides: claude
$ npm install -g @openai/codex               # provides: codex
$ npm install -g @google/gemini-cli          # provides: gemini
$ gh extension install github/gh-copilot     # GitHub Copilot CLI, via gh
```

<details>
<summary><strong>Why aren't Claude Code/Codex/Gemini CLI packaged in Nix like everything else?</strong></summary>

They ship near-weekly. Hand-vendoring each one as a Nix derivation means either pinning to a stale
version forever or re-deriving a hash on every release, a maintenance job I'm not taking on for
tools whose entire value is being current. `nodejs`, their shared runtime, gets the declarative
treatment instead. Installing the actual CLI stays a single `npm install -g`, the same command
upstream already documents.

</details>

`doctor` checks whether each is installed and whether it has a key. Give one a key by adding it to
`~/.config/workspaces-host/credentials` and running `workspaces-host-update`:

```dotenv
ANTHROPIC_API_KEY=sk-ant-yourRealKey
```

<details>
<summary><strong>Why per-invocation credential scoping instead of exporting the key?</strong></summary>

`claude`/`codex`/`gemini`/`aider`/`gh`/`glab` each get their own bash function of the same name
(`home/ai-harness.nix`) that looks for a matching key and sets it only for that one call, never a
shell-wide `export`. That's Constitution Principle III, applied literally: a secret gets resolved
at the point of use, never as an ambient variable available to the whole shell session and
everything running in it, an AI coding agent included. Run `claude` and its wrapper finds the
value, sets `$ANTHROPIC_API_KEY` for that one call, and touches nothing else. `echo
$ANTHROPIC_API_KEY` in the same window comes back empty. If a CLI has its own browser-based
`login` instead (Claude Code and Gemini CLI both do), that works too. The wrapper is a no-op when
nothing's configured, and `doctor` only warns if neither a configured credential nor an existing
login shows up.

</details>

That's everything you need to get started. Everything below is an extra capability. Read it when
you need it.

<details>
<summary><strong>Why this exists</strong></summary>

I didn't build this for "a nice shell." I built it so a human engineer, a teammate who's new to
Linux, a CI/CD pipeline, and an AI coding agent (Claude Code, Codex, an autonomous CI bot,
whatever) can all open a terminal on completely different machines and find the exact same
structure. The same place repos land (`~/workspaces`, managed by `ws-repos`), the same command to
check the environment (`doctor`), the same command to update it (`workspaces-host-update`), the
same shell, the same tools, at the same versions. When everyone and everything on a project,
engineering, DevOps, an agent working overnight, shares one predictable layout, nobody has to
relearn "how this particular machine happens to be set up" before they can do anything useful on
it.

That matters more now, not less, because AI put a real command line in front of people who never
expected to need one. Just about everyone is an engineer some of the time now, and everyone doing
that work deserves the same consistent, capable Linux environment, not a stripped-down one just
because they're newer to it. WSL already gives Windows users the desktop, files, and apps they
know; this is what gives them the same ready-to-go setup on the Linux side. "New to Linux" stays
the only unfamiliar part, not the tooling.

It's also why AI CLIs ship as part of the standard environment (see "Setting up AI harness
credentials" above). Once someone has an API key configured the safe way this repo documents,
they can point an AI harness at their own sandbox and ask it to help fix or improve the setup, the
same way it would help with application code. I want that barrier low on purpose. Lowering it is
most of the point of building this at all.

Here's the thing worth protecting: that consistency. If an AI harness or a person finds a real
improvement while working in one sandbox (a new tool, a better default, an extra `doctor` check, a
smarter install step), it belongs in this repo, via a pull request. Not buried in one person's
credentials file, not a one-off tweak that only exists on their machine. Your credentials file
exists for what's actually personal, your name, your keys, precisely so everything else stays
shared. A good idea stuck in one sandbox helps one person. The same idea merged here helps
everyone, and every CI run, and every agent, who uses this setup afterward.

</details>

Every spec under [`specs/`](specs/), 001 through 017, is implemented: the flake/shell base,
credentials (GitHub/GitLab tokens included), `ws-repos`, `doctor`/rollback, container parity,
compliance/observability tooling, the Java/Postgres toolchain, AI coding agent harness
credentials, Nerd Font/prompt polish, agent-harness project scaffolding, bulk git tooling, secrets
backup/restore, advanced `local.nix` overrides, per-persona workspace profiles (the base profile
stays small on purpose; see "Workspace profiles" below for what moved behind one), a handful of
everyday utilities, and git hooks plus zero-trust networking clients (Lefthook, Tailscale/Nebula).
Each spec's `spec.md` has the exact requirements.

## Your shell

I use bash here, not something else, on purpose: it's what every tutorial and every other
Linux/WSL machine already assumes, so nothing you copy and paste needs translating first. Plain
bash is missing a few things other shells get credit for, so I added them on top:

- **Syntax highlighting and autosuggestions as you type**
  ([`ble.sh`](https://github.com/akinomyoga/ble.sh)): press `→` or `End` to accept a suggestion.
- **Fuzzy history and file search** ([`fzf`](https://github.com/junegunn/fzf)): `Ctrl+R`
  fuzzy-searches history, `Ctrl+T` fuzzy-finds a file, `Alt+C` fuzzy-finds and `cd`s into a
  directory. All three use `fd`, so `.git` and build output get skipped automatically.
- **Smarter directory jumping** ([`zoxide`](https://github.com/ajeetdsouza/zoxide)): `z <part of a
  path>` jumps there by frecency; `zi` picks fuzzily among matches. A separate command, not a
  replacement for `cd`.
- **oh-my-posh**, with its own upgrade nag turned off (see below).

<details>
<summary><strong>Modern replacements for everyday CLI tools</strong> (optional: everything below still works under its own name)</summary>

| Instead of | Try | What's different |
| --- | --- | --- |
| `ls` | `eza` | colorized, git-status-aware, tree view (`eza --tree`) |
| `cat` | `bat` | syntax highlighting, git diff markers in the margin |
| `grep` | `rg` (ripgrep) | much faster, skips `.gitignore`d files automatically |
| `find` | `fd` | simpler syntax, faster, also skips `.gitignore`d files |
| `git diff`/`log -p` | (automatic) | `delta` is already wired in as git's pager |

`ll`/`ls` are aliased to `eza`, `cat` is aliased to `bat --paging=never`. Everything else keeps
its own name; a different flag set would break your muscle memory more than it would help.

</details>

<details>
<summary><strong>Why not <code>oh-my-posh enable autoupgrade</code>?</strong></summary>

Looks like the obvious fix for the "a new release is available" message. It isn't. oh-my-posh's
binary lives in the read-only Nix store, so a self-upgrade either fails outright or, worse,
succeeds by writing a binary Nix has no record of, which breaks the one guarantee this repo exists
to give you: every tool pinned by a lockfile, never resolved against a moving upstream at runtime.
So I silence the message correctly instead (`disable_notice` in `home/shell.nix`); that's a
cosmetic setting, not a version change. Want a newer oh-my-posh? Bump this flake's nixpkgs pin,
same as updating anything else here.

</details>

<details>
<summary><strong>Fonts for the prompt icons</strong> (optional: the prompt works fine without them, just with a few boxes/<code>?</code>s where icons would be)</summary>

The prompt uses small icons, branch name, folder, a clock, from a "Nerd Font," a regular monospace
font with extra symbols bolted on. Every profile installs the font file (`home/fonts.nix`). What's
left is telling your terminal app to actually use it, and that's a setting in the terminal itself.
Nix can't flip that switch for you.

- Check the font's actually there first: `fc-list | grep "JetBrainsMono Nerd Font Mono"` should
  print several `.ttf` paths.
- The exact name to pick: `JetBrainsMono Nerd Font Mono`, also shown as `JetBrainsMono NFM`. Use
  the Mono variant specifically.
- On Windows (Windows Terminal): install the font on the Windows side too. Download
  `JetBrainsMono.zip` from the [Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases),
  install the `.ttf` files, then Windows Terminal → Settings → Profiles → Debian → Appearance →
  Font face → `JetBrainsMono NFM`.
- On Linux with GNOME Terminal: Terminal → Preferences → your profile → Text → uncheck "Use the
  system fixed-width font" → Custom font → `JetBrainsMono Nerd Font Mono`.
- Any other terminal app, kitty, Alacritty, Konsole, iTerm2: the font's already installed
  system-wide, so just point that app's font setting at the same name.
- Check it worked: close and reopen your terminal and look at the prompt. Real icons, not boxes
  or `?` marks.

</details>

## Managing your repos (`ws-repos`)

Keep every project under one predictable layout:

```console
$ nano ~/workspaces/ws-repos.json   # { "repos": [{ "repo": "github.com/org/repo" }] }
$ ws-repos ensure                    # clone-or-pull everything listed
$ ws-repos status                    # dirty/untracked/ahead/behind/locked/stash/clean, across every repo
$ ws-repos inspect                   # list git hosts and repos referenced by *.mgit.code-workspace files
```

Every repo lands at `~/workspaces/<git-host>/<org>/.../<repo>`, the same path segments as its
HTTPS clone URL, so the layout stays predictable and greppable no matter how many hosts or orgs
you're across. `ws-repos ensure` also follows `*.mgit.code-workspace` files (VS Code multi-root
workspaces) inside a repo, symlinking them to `~/workspaces` and recursively pulling in whatever
repos they reference: several independent repos, potentially from different hosts, showing up as
one composed "workspace" with no submodules and no vendoring.

<details>
<summary><strong>Why is this called <code>ws-repos</code> and not <code>mgit</code>, and why does the file suffix still say ".mgit"?</strong></summary>

This is a POSIX-shell port of the "mGit" pattern from
[strategy-coach/workspaces](https://github.com/strategy-coach/workspaces) (`mgit.ts`/
`ws-ensure.ts`): same governed directory convention, same idempotent clone-or-pull, same VS Code
multi-root composition trick. Two things are named differently from upstream, on purpose:

- **The command is `ws-repos`, not `mgit`.** Other, unrelated tools are also named `mgit`. A
  different name avoids that collision entirely. It's a naming choice only; the directory
  convention and file matching are unchanged.
- **The workspace file suffix stays `*.mgit.code-workspace`.** That string is hardcoded in
  upstream `mgit.ts`'s own matcher, not tied to this tool's name. Keep it, and a
  `*.mgit.code-workspace` file written for the original mGit tooling, or for v2's own `mgit`,
  still gets recognized here, unchanged.

This revision also brought `ws-repos status` back up to upstream's own fidelity: it reports a
stuck `index.lock` ("locked") and stash count now, and separates "untracked" from "dirty" the way
upstream's `mGitStatus()` does; an earlier port had simplified both away. Parsing a
`*.mgit.code-workspace` file now tolerates the comments VS Code itself allows there too, a
best-effort filter for `//` and `/* */`, not a full JSONC parser. See spec 003's Assumptions for
the one edge case that misses.

</details>

**On WSL, this matters for speed too, not just organization.** See the `/mnt` note in the
Windows/WSL section above. `doctor` checks this for both `$HOME` and wherever you're standing.

Spec 003 has the full `ws-repos` requirements.

### Bulk changes across many repos, and other git helpers

`ws-repos` (above) decides which repos land under `~/workspaces`. `git-xargs`
([gruntwork-io/git-xargs](https://github.com/gruntwork-io/git-xargs)) is in every profile too: run
a command, or a small Go callback, against many GitHub repos in one shot, and open a PR with the
results in each:

```console
$ git-xargs --repos repo1,repo2,repo3 --branch-name my-fix --commit-message "my fix" -- ./my-script.sh
```

A few more multi-repo git helpers live in the `agent-ops` persona instead of every profile (see
"Workspace profiles" below); they're specialized enough that most people won't reach for them on
day one:

- **`git-extras`** - a grab-bag of everyday `git <cmd>` subcommands (`git summary`, `git
  changelog`, `git effort`, `git delete-merged-branches`, ...).
- **`semtag`** - compute, and optionally apply, the next semantic version git tag: `semtag
  current`, `semtag final -s minor -a`.
- **`git-standup`** - list your commits since your last working day, across one or more repos,
  for daily standups.

## Checking your environment (`doctor`) and rolling back

```console
$ doctor
```

One `PASS`/`WARN`/`FAIL` line per check. Exits non-zero only if something actually failed. By
default you get the essentials: did the install actually work. Nix/flakes, home-manager, the
shell/prompt/direnv, git and its identity, the credentials file, GitHub/GitLab authentication,
`ws-repos`, plus a one-line summary count. Run `doctor --all` for everything else: WSL/SSH/disk/
locale pitfalls, the AI harness CLIs, every ported tool, and every persona-specific check
(compliance, backend, agent-ops, networking) reported as an informational `WARN` when that persona
isn't active. Nothing that matters gets hidden by the terse default. A real `FAIL` always prints,
in either mode.

If an update breaks something, roll back with home-manager's own generation mechanism. No
separate tooling needed. Every `workspaces-host-update`/`home-manager switch` creates a new,
numbered generation instead of editing anything in place, so the one before it is always still
sitting there:

```console
$ home-manager generations
2026-09-13 14:02 : id 6 -> /nix/store/i9k2x...-home-manager-generation   # the broken one
2026-09-13 09:47 : id 5 -> /nix/store/7fa31...-home-manager-generation   # the one before it
$ /nix/store/7fa31...-home-manager-generation/activate   # re-run that generation's own activate script
```

Done. You're back at generation 5, exactly as it was, nothing to reinstall.

## Keeping your sandbox in sync

New features and fixes land on `main` as small, independent, merged changes. Your machine doesn't
pick those up on its own:

```console
$ cd ~/.workspaces-host-v3   # or wherever $WORKSPACES_HOST_REPO points
$ workspaces-host-update      # pulls, re-applies your credentials, re-activates, runs doctor
```

Every interactive shell also checks once a day, in the background (never blocking startup,
silently skipped with no network), whether `$WORKSPACES_HOST_REPO`'s `origin/main` has moved.
Informational only; it never runs the update for you:

```text
workspaces-host-v3: 3 commit(s) behind origin/main - run workspaces-host-update to pick up new features
```

## Workspace profiles (personas)

The base profile (`current`/`default`) stays small on purpose, just what every engineer needs on
day one. Want a specialized set of extra tools on top of it? Activate a persona instead (spec
014):

```console
$ nix build ".#homeConfigurations.current-backend.activationPackage" --impure     # Java+Maven, postgresql/pgpass, redis, docker-compose, httpie
$ nix build ".#homeConfigurations.current-data.activationPackage" --impure        # python3, uv, duckdb
$ nix build ".#homeConfigurations.current-mobile.activationPackage" --impure      # android-tools (adb/fastboot), watchman
$ nix build ".#homeConfigurations.current-agent-ops.activationPackage" --impure   # act, semtag/git-standup/git-extras, gopass, deno, llm
$ nix build ".#homeConfigurations.current-compliance.activationPackage" --impure  # osquery, cnquery, steampipe, openobserve, surveilr
$ nix build ".#homeConfigurations.current-networking.activationPackage" --impure  # tailscale, nebula
$ ./result/activate
```

Personas are additive. Everything the base profile gives you is still there, plus that persona's
own extras. Skip all of them and nothing changes. `doctor` (below) reports every persona-specific
tool as an informational `WARN`, not a problem, when its persona isn't active.

## More everyday tools

A couple more small, general-purpose utilities round out the base profile (spec 015):

- **`wget`**, **`rclone`** - a plain HTTP fetcher, and a directly-runnable `rclone` (not just the
  copy `sensitivectl` uses internally; see "Backing up sensitive local directories" below).
- **`git-chglog`** - generate a `CHANGELOG.md` from your commit history.
- **SSH agent auto-start** - a new login shell starts an SSH agent and loads `~/.ssh/id_ed25519`
  or `~/.ssh/id_rsa`, whichever exists, if nothing's loaded yet. No more manual
  `ssh-agent`/`ssh-add` every session.
- **`cdp`** - an alias that `cd`s to the current git repo's top-level directory.

`gopass` (general secrets management) and `deno` (a general-purpose scripting runtime, with
`deno-run`/`deno-test` aliases) live in the `agent-ops` persona instead. See "Workspace profiles"
above.

<details>
<summary><strong>Why is Deno available at all when this repo's own tools no longer need it?</strong></summary>

v1, the original chezmoi-based repo, called Deno "a core requirement" and used it for
`ws-repos`'s own upstream ancestor (`mgit.ts`) plus most of its custom tooling. v2 rewrote those
specific scripts in POSIX `sh` so this repo's own tooling wouldn't need Deno, but that sidestepped
a different question instead of answering it: should engineers still have Deno available as a
general scripting runtime? v1 said yes; it recommends `deno`+`dax` over `make` for running custom
tasks. I agree, so Deno's provisioned as a plain tool here, independent of what `ws-repos`/`doctor`
happen to be written in, just not in every profile by default, since it's still a specialized
enough choice that most people won't reach for it on day one. That's why it moved to the
`agent-ops` persona.

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

v1's own README carried this as an unchecked roadmap item, "Integrate Lefthook Git hooks
manager...", that v1 itself never built. Turned out to be a clean fit once I actually tried it:
install the tool declaratively via Nix instead of v1's proposed `brew install`, and hand engineers
a documented, copy-in example config instead of forcing hooks on every repo.

</details>

## Zero-trust networking (optional persona)

The `networking` persona (see "Workspace profiles" above) installs the
[Tailscale](https://tailscale.com/) and [Nebula](https://github.com/slackhq/nebula) mesh VPN
clients. No service, no auto-start, no key material. Joining either is always something you do
yourself:

```console
$ nix build ".#homeConfigurations.current-networking.activationPackage" --impure && ./result/activate
$ sudo tailscale up      # interactive login against your own Tailscale account
$ nebula -config nebula.yml   # needs a certificate issued by your mesh's own CA/admin first
```

`doctor --all` reports both clients, informationally. Neither is required for anything else here,
and most people never need this persona at all.

<details>
<summary><strong>Why install the clients but never configure or auto-start them?</strong></summary>

Another item off v1's unfinished roadmap, "Integrate Zero Trust client infrastructure starting
with Tailscale... and then add Nebula...". Nix can provision the *clients* declaratively like
everything else here. Joining an actual mesh (a Tailscale account and its login flow, or a Nebula
CA certificate a network admin issues) is unavoidably a human, out-of-band action, same category
as a git identity or an API key. Constitution Principle III says provisioning a key is a
deliberate, separate, human action, and that applies just as much to network trust material.
Running a server-side control plane (a self-hosted Headscale instance, a Nebula lighthouse) is
infrastructure someone chooses to operate separately; it's not part of one engineer's sandbox.

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

The sandboxed image runs `init-firewall` as root, checks its own allowlist, then drops to a
non-root `agent` user before handing off to the workload. Set `FIREWALL_ALLOWED_DOMAINS` to
override the default allowlist, or `SKIP_FIREWALL=1` as an explicit opt-out on a runtime that
can't grant `NET_ADMIN`. Spec 005 has the details.

## Compliance & observability tooling (optional persona)

This sandbox can audit itself, useful for SOC2 and similar requirements, or just for understanding
what's actually running on the machine. It's specialized enough that it lives in the `compliance`
persona (see "Workspace profiles" above) instead of every profile. Activate it and you get all
five, nothing extra to opt into (spec 006):

```console
$ nix build ".#homeConfigurations.current-compliance.activationPackage" --impure && ./result/activate
```

- **`osqueryi`** (interactive) / `osqueryd` (daemon) - SQL-queryable operating-system
  instrumentation. Linux-only in nixpkgs; `doctor` reports its absence on Darwin as an
  informational `WARN`, not a `FAIL`.
- **`cnquery`** - Mondoo's cloud-native, graph-based asset inventory tool, across
  cloud/Kubernetes/API resources too, not just the local host.
- **`steampipe`** - queries cloud, code, and log sources with plain SQL.
- **`openobserve`** - a self-hostable logs/metrics/traces backend; a binary on `PATH`, not a
  running service. Start it yourself when you actually want to ingest and query telemetry.
- **`surveilr`** - walks files, databases, and APIs and resource-surveils them into a local
  SQLite database. Upstream only ships `x86_64` release binaries for Linux and Darwin; `doctor`
  reports its absence elsewhere as an informational `WARN`.

None of these run anything on their own. They're audit and query tools you reach for, not
background daemons this repo starts for you.

## PostgreSQL credentials (`~/.pgpass`, `~/.psqlrc`, `pgpass`) (optional persona: `backend`)

The `backend` persona (see "Workspace profiles" above) ships `~/.psqlrc`, a full `psql` client
config: colored prompt, sane defaults, admin queries like `settings`, `locks`, `dbsize`, and
bootstraps an empty `~/.pgpass` (mode 600) the first time it activates (spec 007). Add connections
with a small comment-header convention:

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

`--conn-id` takes an extended regex, so `--conn-id=".*"` matches every connection.

## Java toolchain (optional persona: `backend`)

The `backend` persona (see "Workspace profiles" above) installs a JDK (`java`) and Maven (`mvn`),
with `JAVA_HOME` already set. No separate version manager needed (spec 007).

<details>
<summary><strong>Why not SDKMAN! or another Java version manager?</strong></summary>

Nix already pins a reproducible version for every tool in this setup, Java included. A second
version manager on top of that would just duplicate the job. Want a different JDK version or
vendor? Override `home/java.nix`'s `pkgs.jdk`/`pkgs.maven` in a fork.

</details>

## Scaffolding a project for an AI coding agent

`scaffold-agent-harness` (spec 010) copies a fixed template, `AGENTS.md`, `.mcp.json`,
`.claude/settings.json` plus a `SessionStart` hook, `.claude/skills/README.md`, into a project
directory. It never overwrites a file that's already there:

```console
$ cd your-project
$ scaffold-agent-harness
```

Every profile also installs `specify` ([GitHub Spec Kit](https://github.com/github/spec-kit)) and
`backlog` ([Backlog.md](https://github.com/MrLesk/Backlog.md)), so a scaffolded project can start
spec-driven, task-tracked work right away. `specify init` populates `.claude/skills/speckit-*` in
the template's empty skills directory.

## Backing up sensitive local directories (`sensitivectl`)

Got a local directory of sensitive material you want synced to your own remote storage? Not the
credentials file, that's handled above. `sensitivectl` (spec 012) backs it up to, and restores it
from, any `rclone`-supported remote:

```console
$ cat ~/.config/workspaces-host/sensitivectl.json
{ "profiles": { "notes": { "local": "/home/me/Sensitive", "remote": "myremote:backups/sensitive" } } }
$ sensitivectl backup notes
$ sensitivectl restore notes
```

Anything after `--` passes straight through to the underlying `rclone sync` (`-- --dry-run`, say).
`rclone` itself gets configured with your remote's credentials out-of-band (`rclone config`); I
don't manage that here.

## Advanced: personal Nix-level overrides (`local.nix`)

Most people never need this; the credentials file above is the right way to customize identity
and tokens. For a genuinely Nix-level personal tweak (an extra package, a
`workspacesHost.secrets` declaration) that doesn't belong in a fork or PR, copy `local.nix.example`
to `~/.config/workspaces-host/local.nix` (spec 013). Only the `current` profile picks it up.
`default` and every other fixed-identity profile `nix flake check` builds are completely
unaffected by whether one exists, so it's always safe to have one.

## Development

This repo follows [GitHub Spec Kit](https://github.com/github/spec-kit)'s spec-driven workflow:
every feature gets a spec, a plan, and, once built, code, under `specs/<NNN-name>/`. The
non-negotiable principles live in
[`.specify/memory/constitution.md`](.specify/memory/constitution.md); run `nix flake check`
before sending a change. A spec that no longer matches the code is worse than no spec at all. Fix
that in the same change that causes the mismatch, not as a cleanup pass that may never happen.

Prose documentation, this README, any `docs/` guide, a spec's own narrative sections, follows
[`.specify/memory/writing-style.md`](.specify/memory/writing-style.md). A spec's Functional
Requirements, Acceptance Scenarios, and Success Criteria stay in SpecKit's own precise, testable
requirement language instead. See the constitution's "Documentation Voice" principle.
