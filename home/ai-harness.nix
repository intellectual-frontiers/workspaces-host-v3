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
  wrapCli = name: varNames:
    let
      predeclare = lib.concatMapStringsSep "\n" (v: "    local ${v}") varNames;
      varList = lib.concatStringsSep " " varNames;
    in
    ''
      ${name}() {
    ${predeclare}
        for var in ${varList}; do
          f="${secretsEnvDir}/$var"
          if [ -f "$f" ]; then
            export "$var=$(cat "$f")"
          fi
        done
        command ${name} "$@"
      }
    '';

  # llm (spec 008 FR-005, https://llm.datasette.io/) isn't packaged at the
  # top level of nixpkgs - only as a Python library
  # (python3Packages.llm) - so it needs `toPythonApplication` to get a
  # real `bin/llm` wrapper, the same pattern any Python-packaged CLI in
  # nixpkgs needs.
  llmCli = pkgs.python3Packages.toPythonApplication pkgs.python3Packages.llm;
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
  home.packages = with pkgs; [
    nodejs
    aider-chat
    openssh
    gh
    glab
    # llm (spec 008 FR-005) manages its own provider keys via
    # `llm keys set <provider>` - not wrapped by wrapCli, since it has no
    # ambient-env-var credential to scope in the first place.
    llmCli
  ];

  programs.bash.initExtra = lib.concatStrings (map
    ({ name, vars }: wrapCli name vars)
    [
      { name = "claude"; vars = [ "ANTHROPIC_API_KEY" ]; }
      { name = "codex"; vars = [ "OPENAI_API_KEY" ]; }
      { name = "gemini"; vars = [ "GEMINI_API_KEY" "GOOGLE_API_KEY" ]; }
      { name = "aider"; vars = [ "ANTHROPIC_API_KEY" "OPENAI_API_KEY" "GEMINI_API_KEY" "GOOGLE_API_KEY" ]; }
      { name = "gh"; vars = [ "GITHUB_TOKEN" "GH_TOKEN" ]; }
      { name = "glab"; vars = [ "GITLAB_TOKEN" ]; }
    ]);
}
