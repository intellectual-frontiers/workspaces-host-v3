## Verify it worked

```
$ doctor
```

One `PASS`/`WARN`/`FAIL` line per check. Exits non-zero only if something's actually broken. A `WARN` for anything you haven't configured yet (like a blank credential) is normal.

## Typing feels slower than you'd expect? {#typing-feels-slower-than-youd-expect}

This repository uses **bash** by default. Bash here gets fish-like real-time syntax highlighting and history autosuggestions from `blesh`, layered on top of plain bash so every tutorial and copy-pasted snippet still works unchanged. If typing feels slower than you'd expect, here's why, and two ways to fix it.

`blesh`'s default configuration auto-triggers full completion, not just the lightweight grey suggestion, on almost every keystroke. That's the expensive part: it can shell out to real completion scripts (git, docker, and so on) before you've even pressed Tab.

**Option (a): turn off just that one setting.** Tab-completion itself is unaffected; you only lose the auto-popup that runs before you press Tab. Try it in your current shell first:

```
$ bleopt complete_auto_complete=
```

That change lasts for the current shell only. To make it permanent, add it to your personal, machine-specific override file (never touched by `workspaces-host-update`, so it survives every sync):

```
$ nano ~/.config/workspaces-host/local.nix
```

```
{ ... }:
{
  programs.bash.initExtra = ''
    bleopt complete_auto_complete=
  '';
}
```

Then run `workspaces-host-update` to apply it. (More on `local.nix` in [Personalize with local.nix](#going-further/local-nix).)

**Option (b): switch to the `fish` persona.** If you want the real thing instead of a workaround, fish's own line editor (fish 4.x is written in Rust) does highlighting and suggestions natively, with nothing layered on top. See [Combine personas for your role](#day-to-day/personas) for the exact command.

## Your first repo

```
$ nano ~/workspaces/ws-repos.json   # { "repos": [{ "repo": "github.com/org/repo" }] }
$ ws-repos ensure                    # clone-or-pull everything listed
```

Every repo lands at `~/workspaces/<git-host>/<org>/<repo>`, the same path segments as its HTTPS clone URL. If that repo is private, you'll need to authenticate `gh`/`glab` first - see [Authenticate & manage credentials](#day-to-day/credentials/gh-glab-auth) for the one command that does it.

> [!NOTE]
> On WSL: keep repos under `~/workspaces`, not `/mnt/c/Users/...`. Crossing the Windows/Linux filesystem boundary is slow, git especially. `doctor` checks for this too.

## What's next

That's a working shell, one repo cloned, and `doctor` green. For everything you'll reach for after today, credentials, personas, staying in sync, AI coding agents, see [Day to Day](#day-to-day/personas). New to the command line? Every task in Day to Day also has a copy/paste AI-agent prompt you can use instead of typing the commands yourself. Curious why any of this is built the way it is? See [FAQ](#faq/faq).
