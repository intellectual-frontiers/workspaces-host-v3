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
requirements each feature implements. This is a from-scratch rewrite of
[workspaces-host-v2](https://github.com/intellectual-frontiers/workspaces-host-v2):
same purpose, fresh specs, simplest implementation that satisfies them —
see the constitution's "Simplicity Over Completeness" principle.

## What's implemented vs. planned

The specs under [`specs/001-core-flake-shell`](specs/001-core-flake-shell)
through [`specs/005-container-parity`](specs/005-container-parity) are
implemented: the flake/shell base, credentials (including GitHub/GitLab
tokens), `mgit`, `doctor`/rollback, and container parity.

A few more capabilities v2 had are written up as specs but not yet
built — sequenced, not lost:

| Spec | Capability |
| --- | --- |
| [`006-compliance-observability`](specs/006-compliance-observability) | osquery/cnquery/steampipe/OpenObserve/surveilr |
| [`007-java-postgres-toolchain`](specs/007-java-postgres-toolchain) | Pinned JDK/Maven, `~/.pgpass`/`pgpass` CLI |
| [`008-ai-harness-credentials`](specs/008-ai-harness-credentials) | Claude Code/Codex/Gemini CLI/aider install + scoped keys |
| [`009-prompt-theme-polish`](specs/009-prompt-theme-polish) | Nerd Font install + per-terminal setup instructions |
| [`010-agent-harness-scaffolding`](specs/010-agent-harness-scaffolding) | `scaffold-agent-harness`, `specify-cli`, `backlog-md` |
| [`011-bulk-git-tooling`](specs/011-bulk-git-tooling) | `git-extras`, `git-xargs` |
| [`012-secrets-backup-restore`](specs/012-secrets-backup-restore) | `sensitivectl` (rclone-backed backup/restore) |
| [`013-local-nix-overrides`](specs/013-local-nix-overrides) | `local.nix` advanced per-machine Nix overrides |

## Installation

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
3. **From inside that Debian window, run this one line.** A brand-new
   Debian/WSL image doesn't include `curl` yet (nothing does, on a
   minimal install) — this first installs just enough (`curl`, `git`) to
   fetch and run the actual installer, which then does everything else
   itself:
   ```console
   $ sudo apt-get update && sudo apt-get install -y curl git && sh -c "$(curl -fsSL https://raw.githubusercontent.com/intellectual-frontiers/workspaces-host-v3/main/install.sh)"
   ```
   `sudo` asks for the password from step 2 — the only password prompt in
   this whole process. The line can take a few minutes the first time,
   and is safe to run again later (it skips whatever's already done, and
   just updates/reapplies otherwise — that's what `workspaces-host-update`
   does under the hood once you're set up).
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

**One habit worth having from day one**: always keep your project repos
under `~/workspaces` (see "Managing your repos" below), not under
`/mnt/c/Users/...`. WSL can access Windows' files from Linux and vice
versa, but it's slow across that boundary — git especially — and it's
exactly what a WSL warning about "an I/O intensive operation like git" is
telling you if you ever see one. `doctor` checks for this too, for both
`$HOME` and wherever you happen to be standing when you run it.

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
```
```console
$ workspaces-host-update
```

That one command re-applies your setup with the new values *and* finishes
by running `doctor`, so you see immediately whether everything took
effect.

This file:

- **Never leaves your machine.** It lives outside this repository, so
  `git pull`/`workspaces-host-update` can never touch, overwrite, or
  conflict with it.
- **Is protected the same way `~/.ssh` or `~/.aws/credentials` are**:
  `workspaces-host-update` sets it to mode 600 every time it runs, and
  fixes the permissions automatically if anything ever loosens them;
  `doctor` checks this too.
- **Is read by a plain script, not by Nix.** `workspaces-host-update`
  parses it as plain `KEY=value` text (never `source`s it as a shell
  script), writes your git name/email into a file git itself includes
  automatically, and drops each token into a per-command-scoped
  mechanism — a key is only ever visible to the one command that
  actually needs it (`gh`/`glab`), never the rest of your shell.

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

### Why `.envrc` should prefer the ambient variable first

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

### Modern replacements for everyday CLI tools

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

### Why not `oh-my-posh enable autoupgrade`?

It might seem like the obvious fix for the "a new release is available"
message — but oh-my-posh's own binary lives in the read-only Nix store, so
a self-upgrade would either fail outright, or (worse) succeed by writing a
new binary somewhere Nix has no record of — directly undermining the one
guarantee this repository exists to provide (every tool pinned by a
lockfile, not resolved against a mutable upstream at runtime). The message
is silenced correctly instead (`disable_notice` in `home/shell.nix`) — a
cosmetic setting, not a version change. Want a newer oh-my-posh? That's a
nixpkgs pin bump in this flake, the same as updating any other tool.

## Managing your repos (`mgit`)

Keep every project you work on under one predictable layout:

```console
$ nano ~/workspaces/mgit.json   # { "repos": [{ "repo": "github.com/org/repo" }] }
$ mgit ensure                    # clone-or-pull everything listed
$ mgit status                    # dirty/ahead/behind/clean, across every repo
$ mgit inspect                   # list git hosts and repos referenced by *.mgit.code-workspace files
```

Every repo lives at `~/workspaces/<git-host>/<org>/.../<repo>` — the same
path segments as its HTTPS clone URL, so the layout is predictable and
greppable no matter how many hosts/orgs you work across. `mgit ensure`
also follows `*.mgit.code-workspace` files (VS Code multi-root workspaces)
inside a repo, symlinking them to `~/workspaces` and recursively ensuring
whatever repos they reference — several independent repos, potentially
from different hosts, presenting as one composed "workspace" with no
submodules and no vendoring.

**On WSL, this also matters for speed, not just organization** — see the
`/mnt` note in the Windows/WSL section above. `doctor` checks this for
both `$HOME` and wherever you're currently standing.

See spec 003 for the full requirements. Bulk changes across many repos at
once (`git-extras`, `git-xargs`) are planned — see spec 011.

## Checking your environment (`doctor`) and rolling back

```console
$ doctor
```

Prints one `PASS`/`WARN`/`FAIL` line per check and exits non-zero only if
something actually failed. Covers: Nix/flakes, home-manager; the shell,
prompt, and direnv integration, and whether this flake's own pinned bash
actually is your login shell (not just installed); git and its identity;
the credentials file's existence and permissions; GitHub/GitLab
authentication for `gh`/`glab`; SSH key existence and permissions; `mgit`
and the `~/workspaces` layout; every tool this repository installs;
common pitfalls easy to hit if you're new to Linux/WSL — working under
WSL's slower `/mnt` Windows filesystem by mistake (both `$HOME` and
wherever you're standing), low disk space, a misconfigured locale, a
plaintext `~/.netrc` with the wrong permissions, an overly permissive
`umask`, and Docker group membership; and optionally `docker`, for
building/running this flake's container images.

If an update ever breaks something, roll back with home-manager's own
generation mechanism — no separate tooling needed:

```console
$ home-manager generations         # list generations, newest first
$ /nix/store/.../activate          # re-run an earlier generation's own activate script
```

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

## Development

This repository follows [GitHub Spec Kit](https://github.com/github/spec-kit)'s
spec-driven workflow: every feature has a spec, a plan, and (once
implemented) code, under `specs/<NNN-name>/`. See
[`.specify/memory/constitution.md`](.specify/memory/constitution.md) for
the non-negotiable principles, and run `nix flake check` before sending a
change. A spec that no longer matches the code is worse than no spec — a
follow-up fix updates that feature's own spec in the same change, not as
a separate cleanup pass that may never happen.
