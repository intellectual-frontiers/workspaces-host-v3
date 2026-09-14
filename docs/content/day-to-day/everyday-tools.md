## Your shell

Bash, on purpose. It's what every tutorial already assumes. A few things are added on top:

- **Syntax highlighting and autosuggestions** as you type. Press `→` or `End` to accept a suggestion.
- **Fuzzy history and file search**: `Ctrl+R` searches history, `Ctrl+T` finds a file, `Alt+C` finds and jumps into a directory.
- **Smarter `cd`**: `z <part of a path>` jumps there by frecency.
- **Modern replacements**, all optional: `eza` for `ls`, `bat` for `cat`, `rg` for `grep`, `fd` for `find`. `ll`/`ls`/`cat` are already aliased; everything else keeps its own name.

Typing feels slower than you'd expect? See [Verify it worked & your first day](#getting-started/first-day/typing-feels-slower-than-youd-expect) in Getting Started for why, and the two fixes (one of which is switching to the `fish` persona).

## `lefthook`: git hooks, ready to adopt

A git hooks manager is installed in every profile, ready to adopt in any project without writing hook scripts by hand:

```
$ cp templates/lefthook.yml.example ./lefthook.yml
$ lefthook install
```

Edit the copied `lefthook.yml` for the checks your project actually wants (lint, test, format) before committing to it team-wide.

## `sensitivectl`: back up a sensitive directory

Backs up a local directory (SSH keys, a credentials store, anything you'd never want to lose but also never want in git) to any `rclone`-supported remote:

```
$ sensitivectl backup ~/.ssh my-remote:backups/ssh
$ sensitivectl restore my-remote:backups/ssh ~/.ssh
```

Configure the remote itself with `rclone config` first, the same as any other `rclone` use.

## Everything else

- **`wget`, `rclone`**: a plain fetcher and a directly-runnable `rclone`.
- **`git-chglog`**: generate a `CHANGELOG.md` from your commit history.
- **SSH agent auto-start**: a new login shell loads your key automatically.
- **`cdp`**: jumps to the current git repo's top-level directory.
