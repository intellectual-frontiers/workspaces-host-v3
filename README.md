# workspaces-host-v3

A ready-to-use engineering sandbox for your own computer. One command gives
you a configured bash shell and prompt, git identity handled safely, a way
to keep many git repositories organized, and a growing set of everyday
developer tools — set up identically every time, whether that's on Linux, a
Mac, WSL2, inside a container, or in a cloud AI-agent session.

It's built with **Nix flakes + home-manager**: the whole setup is described
in code (this repository) rather than a list of manual steps, so it
rebuilds byte-for-byte the same way anywhere.

See [`.specify/memory/constitution.md`](.specify/memory/constitution.md) for
the principles behind these design choices, and [`specs/`](specs/) for the
requirements each feature implements. This is a from-scratch rewrite of
[workspaces-host-v2](https://github.com/intellectual-frontiers/workspaces-host-v2):
same purpose, fresh specs, simplest implementation that satisfies them —
see the constitution's "Simplicity Over Completeness" principle.

## What's implemented vs. planned

The specs under [`specs/001-core-flake-shell`](specs/001-core-flake-shell)
through [`specs/005-container-parity`](specs/005-container-parity) are
implemented. A few more capabilities v2 had are written up as specs but not
yet built — see [`specs/006-compliance-observability`](specs/006-compliance-observability)
through [`specs/009-prompt-theme-polish`](specs/009-prompt-theme-polish).
They're sequenced, not lost.

## Installation

```console
$ sh -c "$(curl -fsSL https://raw.githubusercontent.com/intellectual-frontiers/workspaces-host-v3/main/install.sh)"
```

This installs Nix (if needed), enables flakes, clones this repo to
`~/.workspaces-host-v3`, builds and activates the `current` home-manager
profile (the one that picks up your real username/home directory), and
makes its pinned bash your login shell.

Then, in a new shell:

```console
$ nano ~/.config/workspaces-host/credentials   # fill in your name and email
$ workspaces-host-update                       # applies it, re-activates, runs doctor
$ doctor                                        # verify everything
```

Manual equivalent, if you'd rather run each step yourself:

```console
$ sh <(curl -L https://nixos.org/nix/install) --no-daemon
$ mkdir -p ~/.config/nix
$ echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
$ git clone https://github.com/intellectual-frontiers/workspaces-host-v3.git ~/.workspaces-host-v3
$ cd ~/.workspaces-host-v3
$ nix build ".#homeConfigurations.current.activationPackage" --impure
$ export HOME_MANAGER_BACKUP_EXT=pre-workspaces-host-backup
$ ./result/activate
```

## Setting up your credentials

`~/.config/workspaces-host/credentials` is a plain `KEY=value` file — not
Nix, nothing to install first (see [`credentials.example`](credentials.example)
for the exact format). `workspaces-host-update` creates it from that
template the first time you run it. Fill in `GIT_NAME`/`GIT_EMAIL` and
re-run `workspaces-host-update`; it writes your git identity into a
generated include file, re-activates your profile, and runs `doctor` to
confirm it worked. Your real copy lives entirely outside this repository
and is never touched by `git pull`.

Rotating a value later is the same two steps: edit the file, re-run
`workspaces-host-update`. See spec 002 for the full requirements, including
the advanced sops-based path (`workspacesHost.secrets` in `home/secrets.nix`)
for anyone who wants field-level encryption at rest.

## Managing your repos (`mgit`)

Keep every project you work on under one predictable layout:

```console
$ nano ~/workspaces/mgit.json   # { "repos": [{ "repo": "github.com/org/repo" }] }
$ mgit ensure                    # clone-or-pull everything listed
$ mgit status                    # dirty/ahead/behind/clean, across every repo
$ mgit inspect                   # list git hosts and repos referenced by *.mgit.code-workspace files
```

`mgit ensure` also follows `*.mgit.code-workspace` files (VS Code multi-root
workspaces) inside a repo, symlinking them to `~/workspaces` and recursively
ensuring whatever repos they reference. See spec 003 for details.

## Checking your environment (`doctor`) and rolling back

```console
$ doctor
```

Prints one `PASS`/`WARN`/`FAIL` line per check (Nix, shell/prompt/direnv,
git, credentials, `mgit`, every installed tool) and exits non-zero only if
something actually failed — a `WARN` (like an unset git email) is
informational.

If an update ever breaks something, roll back with home-manager's own
generation mechanism — no separate tooling needed:

```console
$ home-manager generations         # list generations, newest first
$ /nix/store/.../activate          # re-run an earlier generation's own activate script
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
workload. Set `FIREWALL_ALLOWED_DOMAINS` to override the default allowlist,
or `SKIP_FIREWALL=1` as an explicit opt-out on a runtime that can't grant
`NET_ADMIN`. See spec 005 for details.

## Development

This repository follows [GitHub Spec Kit](https://github.com/github/spec-kit)'s
spec-driven workflow: every feature has a spec, a plan, and (once
implemented) code, under `specs/<NNN-name>/`. See
[`.specify/memory/constitution.md`](.specify/memory/constitution.md) for the
non-negotiable principles, and run `nix flake check` before sending a
change.
