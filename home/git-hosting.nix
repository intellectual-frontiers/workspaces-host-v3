{ config, lib, pkgs, ... }:

let
  # Where a credential ends up as a plain file named after its own
  # variable - written by `workspaces-host-update` (see README's
  # "Setting up your credentials" section), or by home/secrets.nix's
  # optional sops-based `path = "env/VARNAME"` mechanism for anyone who
  # wants field-level encryption at rest. Both feed the same directory;
  # this module doesn't care which one wrote a given file.
  secretsEnvDir = "${config.xdg.stateHome}/workspaces-host/secrets/env";

  # Constitution Principle III ("secrets never touch the agent's shell
  # unscoped") applies to gh/glab exactly the same as any other
  # credential: a bash function of the same name looks for a decrypted
  # secret file matching one of its known variable names and, if found,
  # exports it only for its own invocation of the real binary - nothing
  # leaks into the interactive shell that called it. If no matching
  # secret is configured, this is a transparent no-op pass-through -
  # `gh`/`glab`'s own stored `auth login` state works exactly as if this
  # wrapper didn't exist.
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
in
{
  # `openssh` for engineers using SSH-based git remotes (doctor's SSH
  # key check assumes ssh-keygen is actually available, not just
  # documented); `gh`/`glab` for GitHub/GitLab from the CLI.
  home.packages = with pkgs; [
    openssh
    gh
    glab
  ];

  programs.bash.initExtra = lib.concatStrings (map
    ({ name, vars }: wrapCli name vars)
    [
      { name = "gh"; vars = [ "GITHUB_TOKEN" "GH_TOKEN" ]; }
      { name = "glab"; vars = [ "GITLAB_TOKEN" ]; }
    ]);
}
