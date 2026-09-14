The base profile stays small: your shell, git, credentials, `ws-repos`, and AI coding agent tooling. A persona adds one more specialized set of tools on top, when you actually need it. (Curious why the base profile stays small instead of including all of this? See [Why the base profile stays small](#faq/faq/why-personas).)

## What's available

| Persona | Adds |
| --- | --- |
| `backend` | Java+Maven, PostgreSQL client/`pgpass`, Redis, docker-compose, httpie |
| `data` | python3, uv, duckdb |
| `mobile` | android-tools (adb/fastboot), watchman |
| `agent-ops` | act, semtag/git-standup/git-extras, gopass, deno, llm |
| `compliance` | osquery, cnquery, steampipe, openobserve, surveilr |
| `networking` | Tailscale, Nebula |
| `fish` | fish shell, with the same aliases and prompt bash gets |

Personas are additive and they combine: everything the base profile gives you is still there, plus every persona's extras, plus each other's. Activate none and nothing changes. Activate `backend` and `fish` both, and every future `workspaces-host-update` builds both together, automatically, for as long as you keep them activated.

> [!TIP]
> The `fish` persona only makes `fish` and its config available. It never changes your login shell, the same way activating `networking` never joins a Tailscale mesh for you. To actually use it day to day, run these two commands (the same way on Linux generally, WSL included, and macOS - anywhere `chsh` validates against `/etc/shells`):
>
> ```
> $ echo "$(which fish)" | sudo tee -a /etc/shells
> $ chsh -s $(which fish)
> ```
>
> The first line is required: a Nix-installed shell isn't in `/etc/shells` by default, and `chsh` refuses any shell that isn't. Then close this window and open a new one. `doctor` checks for either bash or fish as your login shell, so switching never shows up as a problem.

## Finding and checking personas

Don't want to remember the table above? `ws-persona` prints it for you, along with the exact command to turn each one on:

```
$ ws-persona list
```

Not sure what you already have active?

```
$ ws-persona current
```

This shows two things, and they can briefly disagree: what's **activated** (recorded in `~/.config/workspaces-host/personas`, applied on your next `workspaces-host-update`) and what's **detected** (one marker tool per persona, like `mvn` for `backend`, actually on your `PATH` right now). Activate a persona and it shows as activated immediately, but not detected until you actually rebuild.

> [!NOTE]
> Detection is a quick signal, not a certainty - it can occasionally miss or over-report if you've installed something similar yourself, outside this flake. Run `doctor --all` for the full, authoritative picture.

## Activating one (or several)

Record it, then update:

```
$ ws-persona activate backend
$ workspaces-host-update
```

`workspaces-host-update` runs `doctor` right after, so you see immediately whether it worked. Activate as many as you want the same way; each one adds to the others rather than replacing them, and the choice sticks - no environment variable to remember on your next update, next week or next year.

Changed your mind about one?

```
$ ws-persona deactivate backend
$ workspaces-host-update
```

Want to try a persona once without committing to it - build it in isolation, see if you like it, without touching your activated list?

```
$ WORKSPACES_HOST_PROFILE=current-backend workspaces-host-update
```

That one-off build ignores your activated list entirely (it's just `backend`, nothing else), and doesn't change it either. Prefer the plain Nix commands instead of `workspaces-host-update` for that one-off?

```
$ nix build ".#homeConfigurations.current-backend.activationPackage" --impure
$ ./result/activate
```

## Try with AI

You need a specialized tool a persona provides (Java, Python, Tailscale, and so on) but you don't remember the exact command.

```
Activate the backend persona for my workspaces-host-v3 sandbox and confirm it worked.
```

(Assumes you already have an AI coding agent running in this sandbox - see [Use AI coding agents safely](#day-to-day/ai-agents) if not.)
