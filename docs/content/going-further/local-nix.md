`~/.config/workspaces-host/local.nix` is the one supported place for personal, machine-specific Nix-level overrides - outside this repository entirely, so `git pull`/`workspaces-host-update` never touches, overwrites, or conflicts with it. Most people never need this file at all; the plain credentials file (see [Authenticate & manage credentials](#day-to-day/credentials)) covers the common case. This is for the rest.

> [!NOTE]
> Only the `current` profile picks this up (`home-manager switch --flake .#current --impure`, what `workspaces-host-update` and `install.sh` both use). `default` and every fixed-identity profile `nix flake check` builds are completely unaffected by this file's presence or absence - so a mistake here can never break CI or anyone else's build.

## A durable `bleopt` tweak

The one example most people actually reach for: making a session-only `bleopt` setting (see [Verify it worked & your first day](#getting-started/first-day/typing-feels-slower-than-youd-expect)) survive every future sync.

```
$ nano ~/.config/workspaces-host/local.nix
```

```nix
{ ... }:
{
  programs.bash.initExtra = ''
    bleopt complete_auto_complete=
  '';
}
```

```
$ workspaces-host-update
```

## Overriding your git identity at the Nix level

Rarely needed - the credentials file is the recommended path for this - but available if you specifically want it declared here instead:

```nix
{ ... }:
{
  programs.git.userName = "Your Name";
  programs.git.userEmail = "you@example.com";
}
```

## Adding a package only this machine needs

```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.some-extra-tool ];
}
```

Use this for something genuinely personal - a tool nobody else on the team needs. If it's actually useful to everyone, it belongs in the repository itself instead (see [Add a tool or write a new persona](#going-further/add-a-tool-or-persona)), not in a file only you have.

## Combining more than one override

`local.nix` is a normal home-manager module, so everything above can live in the same file - and, since it's just an `imports`-able module, a savvy reader could even point it at an entire extra persona module by absolute path. That's an edge case, not a documented workflow: `ws-persona activate` (see [Combine personas for your role](#day-to-day/personas)) is the supported way to combine personas.
