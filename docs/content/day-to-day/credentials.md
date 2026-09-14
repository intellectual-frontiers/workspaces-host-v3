## GitHub and GitLab: one command, no token to manage {#gh-glab-auth}

Run this once, per host:

```
$ gh auth login       # answer yes when it asks to authenticate git
$ glab auth login     # same prompt, for gitlab.com
```

That's it. One command authenticates the `gh`/`glab` CLIs and git together, so cloning a private repo (what `ws-repos ensure` does under the hood) just works. No token to create, copy, or paste anywhere - this is the preferred way, and all most people ever need.

Using a private, self-hosted GitLab instead of gitlab.com? Point `glab` at it by hostname:

```
$ glab auth login --hostname gitlab.mycompany.com
```

Add that host's repos to `ws-repos.json` the same way, using the hostname instead of `gitlab.com`:

```
{ "repo": "gitlab.mycompany.com/team/project" }
```

`doctor` reports whether `gh`/`glab` are authenticated (see [Stay in sync & recover](#day-to-day/sync-recover/checking-your-environment)).

## Your name, email, and any API keys {#your-name-email-and-any-api-keys}

Everything else, your git name/email and things like an AI coding agent's API key, goes in one plain text file, outside the repository entirely: `~/.config/workspaces-host/credentials`. Just `KEY=value` lines. No Nix syntax, no encryption tool to learn first. (Curious why a plain file? See [Why a plain credentials file](#faq/faq/why-credentials-file).)

```
$ nano ~/.config/workspaces-host/credentials
```

```
GIT_NAME=Your Name
GIT_EMAIL=you@example.com

ANTHROPIC_API_KEY=sk-ant-yourRealKey
```

```
$ workspaces-host-update
```

That one command applies your changes and runs `doctor` right after, so you see immediately whether it worked. Rotating a key later is the same two steps: edit the line, run `workspaces-host-update` again.

> [!TIP]
> Need a credential this file doesn't have a line for (a cloud token, a project API key)? Add it with whatever name makes sense. `workspaces-host-update` writes anything that isn't `GIT_NAME`/`GIT_EMAIL` into `~/.local/state/workspaces-host/secrets/env/<NAME>`, ready for a project's own `.envrc`.

This file also has `GITHUB_TOKEN`/`GITLAB_TOKEN` lines. Skip them unless something *other than* `gh`/`glab` specifically needs a raw token value, a script, or a project's own `.envrc`. `gh auth login`/`glab auth login` above already covers `gh`, `glab`, and git; filling these in is a second credential to create and keep track of, not a requirement.

Before committing anything, check what's staged (`git diff --staged`) and scan for secrets with the tool that's already installed:

```
$ gitleaks detect --source . -v
```

## Try with AI

You have a new key (an AI coding agent's API key, say) and don't want to hand-edit a config file wrong. For GitHub/GitLab specifically, skip this and just run `gh auth login`/`glab auth login` yourself - no file to edit.

```
Open my ~/.config/workspaces-host/credentials file, add a line for ANTHROPIC_API_KEY with the value I give you next, then run workspaces-host-update and show me the doctor output.
```
