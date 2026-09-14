## The one question that decides where a tool goes

Does every engineer need this on day one, or only someone doing a specific kind of work? The base profile (`home/`) answers the first question; a persona (`home/profiles/`) answers the second. That's Constitution Principle V, simplicity over completeness, applied directly - see [Why the base profile stays small](#faq/faq/why-personas) for the full reasoning.

## Adding a tool everyone needs

Add the package to the right shared module under `home/` - `tools.nix` for a plain everyday CLI, or its own file if it needs real configuration (the way `git.nix`, `ai-harness.nix`, and `secrets.nix` each own one concern). A one-line addition:

```nix
# home/tools.nix
home.packages = with pkgs; [
  # ...
  your-new-tool
];
```

Then validate:

```
$ nix flake check --all-systems
$ nix build ".#homeConfigurations.default.activationPackage"
```

A change to a shared module affects every persona, so also rebuild at least one persona alongside the base profile before calling it done (see [Container & CI parity](#going-further/container-ci) for the full validation loop).

## Adding a tool only some engineers need

That's a persona. Two ways to get there:

**Extend an existing persona**, if the tool genuinely belongs with what that persona already covers (a new PostgreSQL-adjacent CLI in `backend`, say):

```nix
# home/profiles/backend.nix
home.packages = with pkgs; [
  # ...
  your-new-tool
];
```

**Write a new persona**, if it doesn't fit anywhere existing:

1. Create `home/profiles/<name>.nix`:

   ```nix
   { pkgs, ... }:
   {
     home.packages = with pkgs; [
       your-tool
     ];
   }
   ```

   Import the shared `./home` module set too if the persona needs a whole subsystem rather than plain packages (the way `backend` imports `home/java.nix`, or `fish` enables `programs.fish`) - a persona module may import an existing shared module; the "own extra `home.packages`" rule is about not touching *other* modules' configuration, not about which file a persona's own additions live in.

2. Register it in `flake.nix`'s `personaModules`:

   ```nix
   personaModules = {
     # ...
     your-name = ./home/profiles/your-name.nix;
   };
   ```

   This alone gives you `homeConfigurations.your-name` (fixed test identity, for CI) and `homeConfigurations.current-your-name` (real identity, that persona in isolation) - everything else (combining, persisting, `ws-persona list`/`current`) works automatically once the module exists.

3. Add it to `ws-persona`'s own table (`pkgs/ws-persona/ws-persona`) so `list`/`current`/`activate`/`deactivate` know about it - a plain `name:marker:description` line, no flake evaluation involved:

   ```
   your-name:some-marker-binary:What this persona adds, in one line
   ```

   Pick a marker binary that's a reliable, unambiguous signal the persona is active (a tool this persona and only this persona installs).

4. Validate the new persona builds and combines correctly:

   ```
   $ nix build ".#homeConfigurations.your-name.activationPackage"
   $ nix build ".#homeConfigurations.current-your-name.activationPackage" --impure
   ```

## Write the spec first

A new persona, or any change that adds a real capability, gets a spec before code - see [Extend the repo with an AI agent](#going-further/extend-with-ai) for the full spec-driven workflow this repository follows for every feature, core and backlog alike.
