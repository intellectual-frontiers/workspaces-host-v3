{ lib, ... }:

{
  # ~/workspaces is the governed root ws-repos (pkgs/ws-repos) clones/pulls
  # repos into, following the <git-host>/<org>/.../<repo> convention. The
  # directory and an empty repo-list config are created once, on first
  # activation, and never touched again on later activations - this is
  # per-user declared state (which repos to track), not something
  # home-manager should own or overwrite.
  #
  # README.md is the opposite: a generated reference, not a config file,
  # so it's overwritten on every activation the same way any other
  # home-manager-managed file would be - it never has real content of
  # its own to lose, and staying current with ws-repos/doctor matters
  # more than letting someone edit it by hand.
  home.activation.wsReposWorkspace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    WORKSPACES_HOME="$HOME/workspaces"
    $DRY_RUN_CMD mkdir -p "$WORKSPACES_HOME"
    if [ ! -f "$WORKSPACES_HOME/ws-repos.json" ]; then
      $DRY_RUN_CMD cat > "$WORKSPACES_HOME/ws-repos.json" <<'JSON'
{
  "repos": []
}
JSON
    fi
    $DRY_RUN_CMD cat > "$WORKSPACES_HOME/README.md" <<'MD'
# Workspaces

Every git repository you work on lives here, one directory per repo, under a path that matches
its clone URL: `<git-host>/<org>/.../<repo>`. `ws-repos` manages this layout. `doctor` checks that
everything, your GitHub/GitLab authentication included, actually works.

```
~/workspaces/
├── ws-repos.json
├── github.com/
│   └── acme/
│       └── billing-api/
├── gitlab.com/
│   └── acme/
│       └── payments/
└── gitlab.mycompany.com/
    └── platform/
        └── infra/
```

## Quick reference

| Command | What it does |
| --- | --- |
| `ws-repos ensure` | Clone every new repo in `ws-repos.json`. Pull every repo already cloned. |
| `ws-repos status` | Show dirty, untracked, ahead, behind, locked, and stashed state for every repo here. |
| `ws-repos inspect` | List every git host and repo referenced by a `*.mgit.code-workspace` file here. |
| `doctor` | Check the essentials: Nix, shell, git, credentials, GitHub/GitLab auth, `ws-repos`. |
| `doctor --all` | Check everything else too: every tool, every persona-specific check. |
| `gh auth login` | Authenticate git and the `gh` CLI against github.com. Run once, for private GitHub repos. |
| `glab auth login --hostname <host>` | Authenticate git and the `glab` CLI against a GitLab instance. Run once per instance, for private repos. |

## Add a repo

Edit `ws-repos.json`:

```json
{
  "repos": [
    { "repo": "github.com/acme/billing-api" },
    { "repo": "gitlab.com/acme/payments" },
    { "repo": "gitlab.mycompany.com/platform/infra" }
  ]
}
```

Run:

```
$ ws-repos ensure
```

Add `"fresh": true` to one entry to delete and re-clone it instead of pulling.

## Clone from GitHub

A public repo needs nothing extra. Add it to `ws-repos.json` and run `ws-repos ensure`.

A private repo needs one thing done once: run `gh auth login` and answer yes when it asks to
authenticate git with your GitHub credentials. After that, `ws-repos ensure` clones and pulls
your private repos the same way it does public ones.

## Clone from GitLab (gitlab.com)

Same pattern. A public repo needs nothing extra. A private repo needs `glab auth login` run
once, answering yes to the same git-credentials prompt.

## Clone from a private, self-hosted GitLab

Point `glab` at your instance and log in once:

```
$ glab auth login --hostname gitlab.mycompany.com
```

Answer yes to the git-credentials prompt. Add the repo to `ws-repos.json` the same way, using
your instance's hostname instead of `gitlab.com`:

```json
{ "repo": "gitlab.mycompany.com/platform/infra" }
```

Run `ws-repos ensure`. It clones from any host this way; nothing about the command changes per
host.

## Check your environment

Run `doctor` any time something looks wrong. It reports GitHub/GitLab authentication, your
credentials file, and `ws-repos` itself, one PASS/WARN/FAIL line per check.

```
$ doctor
```

Run `gh auth status` or `glab auth status` directly for more detail than doctor's one-line
summary, if it reports an authentication problem.

## Secrets, in short

Your GitHub/GitLab tokens and git identity go in one plain file, outside every repo you clone
here: `~/.config/workspaces-host/credentials`. Edit it, then run `workspaces-host-update` to
apply it.

```
$ nano ~/.config/workspaces-host/credentials
$ workspaces-host-update
```

Never commit a token. Before committing anything in a repo here, scan for secrets with the tool
that's already installed:

```
$ gitleaks detect --source . -v
```

## Full documentation

This file covers daily use. For installation, the technical architecture, and the reasoning
behind every design decision, see
[intellectual-frontiers.github.io/workspaces-host-v3](https://intellectual-frontiers.github.io/workspaces-host-v3/).
MD
  '';
}
