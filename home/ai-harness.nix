{ config, lib, pkgs, ... }:

let
  # Where a credential ends up as a plain file named after its own
  # variable - written directly by `workspaces-host-update` (see
  # README's "Setting up your credentials" section) for the common
  # case, or by home/secrets.nix's optional sops-based
  # `path = "env/VARNAME"` mechanism for anyone who specifically wants
  # field-level encryption at rest. Both feed the same directory; this
  # module doesn't care which one wrote a given file, only that it
  # might be there.
  secretsEnvDir = "${config.xdg.stateHome}/workspaces-host/secrets/env";

  # Constitution Principle III ("secrets never touch the agent's shell
  # unscoped") is explicit and non-negotiable: a credential MUST be
  # resolved "at the point of use," never as an ambient variable
  # available to the whole shell session. So instead of exporting a
  # configured key into every interactive shell, each known CLI gets a
  # bash function of the same name that:
  #   1. `local`-declares each of its known credential variable names
  #      at the function's own scope,
  #   2. looks for a decrypted secret file matching one of those names,
  #      and if found, `export`s it, and
  #   3. calls `command <name> "$@"` (bypassing this very function) to
  #      run the real binary, however it was installed (`npm install
  #      -g` or a Nix package).
  # Once the function returns, every one of these variables - local to
  # it - is gone; nothing leaks into the interactive shell that called
  # it. If no matching secret is configured, this is a transparent
  # no-op pass-through - a CLI's own browser-based `login` flow (or
  # `gh`/`glab`'s own stored auth, or an already-set env var from
  # outside) works exactly as if this wrapper didn't exist.
  #
  # `skipFirstArgs` (a list of the CLI's own first-argument subcommand
  # names, `[ ]` for "none") exists for one specific conflict: `gh auth
  # login`/`glab auth login` manage that CLI's own persistent, stored
  # credentials, and both CLIs refuse to run an interactive login at all
  # once GH_TOKEN/GITHUB_TOKEN/GITLAB_TOKEN is already present in the
  # environment (their own upstream behavior, not something this repo
  # controls) - so a configured credentials-file token, forced into
  # *every* invocation including `auth login` itself, silently broke the
  # one command meant to set auth up in the first place (see the issue
  # this fixed: a stale or placeholder token in the credentials file
  # made `gh auth login` fail until the reader learned to bypass this
  # very wrapper with `command gh auth login`). Any subcommand named
  # here skips the export loop entirely, so `gh auth ...`/`glab auth
  # ...` always talk to the real, unwrapped CLI and manage its own
  # stored credentials exactly as if this wrapper didn't exist; every
  # other subcommand (`gh repo clone`, `gh pr list`, ...) still benefits
  # from the configured token as documented (spec 002's FR-008a).
  wrapCli = name: varNames: skipFirstArgs:
    let
      predeclare = lib.concatMapStringsSep "\n" (v: "    local ${v}") varNames;
      varList = lib.concatStringsSep " " varNames;
      exportBlock = ''
        for var in ${varList}; do
          f="${secretsEnvDir}/$var"
          if [ -f "$f" ]; then
            export "$var=$(cat "$f")"
          fi
        done
      '';
      body =
        if skipFirstArgs == [ ] then
          exportBlock
        else
          ''
            case "''${1:-}" in
            ${lib.concatStringsSep "|" skipFirstArgs})
                ;;
              *)
            ${exportBlock}
                ;;
            esac
          '';
    in
    ''
      ${name}() {
    ${predeclare}
      ${body}
        command ${name} "$@"
      }
    '';
in
{
  # AI-assisted CLI tooling, so an AI harness can help configure this
  # sandbox itself right after install (edit the credentials file,
  # explore a `doctor` WARN, etc.), not just help with application
  # code.
  #
  # `aider-chat` is genuinely packaged in nixpkgs and provider-agnostic
  # (works with Claude, GPT, Gemini, ... via whichever API key you
  # export), so it's installed directly here, the same as every other
  # tool in this repo. `gh`/`glab`/`openssh` are here too since they get
  # the exact same credential-wrapping treatment as the AI CLIs below.
  #
  # Claude Code (`@anthropic-ai/claude-code`), OpenAI's Codex CLI
  # (`@openai/codex`), and Google's Gemini CLI (`@google/gemini-cli`)
  # are NOT Nix-packaged here on purpose: they ship near-weekly
  # releases, and hand-vendoring each one as a `buildNpmPackage`
  # derivation would mean either pinning to a stale version
  # indefinitely or re-deriving a new npm hash on every release - a
  # maintenance burden this repo isn't taking on for tools whose whole
  # value is being current. `nodejs` (their shared runtime) is
  # provisioned here instead, so installing the actual CLI is just the
  # one `npm install -g` command upstream already documents - see
  # README's "Setting up AI harness credentials" section for the exact
  # commands and the safe way to give each one its API key.
  #
  # `python3` and `uv` are the same kind of shared runtime, for the
  # other half of the agent ecosystem: most MCP servers an agent's own
  # `.mcp.json` references (the official reference servers included -
  # fetch, git, sqlite, ...) are Python packages launched via `uvx
  # <package>`, with no separate install step of their own, the same
  # way `npx` works for a Node-based one. Both used to live behind the
  # `data` persona; that persona is gone now (spec 014's own "the data
  # persona is removed" revision) - `uv`/`python3` moved here, and its
  # other package, `duckdb`, moved to home/tools.nix's everyday-tools
  # group, since neither needed a persona to justify gating them.
  #
  # `playwright-driver.browsers` (spec 008 FR-007): a browser-automation
  # MCP server (Playwright MCP, the Puppeteer MCP server, and others
  # like them) is as central to this ecosystem as a `uvx`/`npx`-launched
  # one, but needs an actual browser binary, not just a language
  # runtime - without one already on this machine, its first launch
  # downloads its own ~170MB+ Chromium, every time a fresh sandbox is
  # built. `home.sessionVariables` below points the Playwright-style
  # download path at this pinned package instead, so that download
  # never has to happen. Unlike every other package in this file,
  # nixpkgs' own `playwright-driver` fetches prebuilt, per-platform
  # browser archives rather than building Chromium from source, so (and
  # this is the one case in this repo where that matters) it's actually
  # available on all four systems this flake targets, Darwin included.
  #
  # `playwright-test` provides the actual `playwright` CLI (codegen,
  # `playwright test`, trace viewer, ...), genuinely nixpkgs-packaged
  # like `aider-chat` above, not merely an engine something else drives
  # - and nixpkgs keeps it version-locked to `playwright-driver` itself
  # (both 1.52.0 as of this writing), so it always talks to the exact
  # browser revision `playwright-driver.browsers` actually has.
  home.packages = with pkgs; [
    nodejs
    aider-chat
    python3
    uv
    playwright-driver.browsers
    playwright-test
    openssh
    gh
    glab
  ]
  # Plain `chromium` (for `PUPPETEER_EXECUTABLE_PATH` below) IS built
  # from source, and nixpkgs only carries that build for Linux (checked
  # against this flake's own pinned nixpkgs: `meta.platforms` lists
  # only Linux variants, no Darwin at all) - so, same as `osqueryi`
  # (doctor's compliance-persona check) and `init-firewall`, it's
  # Linux-only here too, rather than breaking evaluation on Darwin for
  # every engineer, only some of whom even use a Puppeteer-based MCP
  # server.
  ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.chromium ];

  # PLAYWRIGHT_BROWSERS_PATH/PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD: nixpkgs'
  # own documented pattern for `playwright-driver.browsers`, pinned to
  # the exact browser revision the `playwright` package nixpkgs carries
  # expects - set unconditionally, since the package above is available
  # on every system. PUPPETEER_EXECUTABLE_PATH/PUPPETEER_SKIP_DOWNLOAD
  # is the same idea for Puppeteer (and anything built on it, including
  # the official Puppeteer MCP server), but only where `chromium` above
  # actually installed - Darwin falls back to Puppeteer's own download
  # until nixpkgs packages Chromium there too.
  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
  } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    PUPPETEER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
    PUPPETEER_SKIP_DOWNLOAD = "true";
  };

  programs.bash.initExtra = lib.concatStrings (map
    ({ name, vars, skipFirstArgs ? [ ] }: wrapCli name vars skipFirstArgs)
    [
      { name = "claude"; vars = [ "ANTHROPIC_API_KEY" ]; }
      { name = "codex"; vars = [ "OPENAI_API_KEY" ]; }
      { name = "gemini"; vars = [ "GEMINI_API_KEY" "GOOGLE_API_KEY" ]; }
      { name = "aider"; vars = [ "ANTHROPIC_API_KEY" "OPENAI_API_KEY" "GEMINI_API_KEY" "GOOGLE_API_KEY" ]; }
      { name = "gh"; vars = [ "GITHUB_TOKEN" "GH_TOKEN" ]; skipFirstArgs = [ "auth" ]; }
      { name = "glab"; vars = [ "GITLAB_TOKEN" ]; skipFirstArgs = [ "auth" ]; }
    ]);
}
