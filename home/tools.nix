{ pkgs, ... }:

let
  # ws-repos, doctor, workspaces-host-update, sensitivectl, specify-cli,
  # backlog-md, scaffold-agent-harness, git-xargs (pkgs/default.nix) -
  # built as flake packages, but only actually land on PATH once they're
  # also listed in home.packages like every other tool here. Persona-
  # specific ported tools (pgpass -> backend, surveilr -> compliance,
  # semtag/git-standup -> agent-ops) are added by their own persona
  # module instead of here (a newbie-simplification pass), so activating
  # no persona keeps this list to what every profile actually needs.
  ported = import ../pkgs { inherit pkgs; };
in
{
  home.packages = (with ported; [
    ws-repos
    workspaces-host-update
    doctor
    sensitivectl
    specify-cli
    backlog-md
    scaffold-agent-harness
    git-xargs
  ]) ++ (with pkgs; [
    # Everyday CLI tools (spec 001 FR-007). `ripgrep`/`fd` back fzf's
    # file/dir widgets (home/shell.nix), `jq`/`findutils` back `ws-repos`
    # (pkgs/ws-repos), `eza`/`bat` are the aliased `ls`/`cat` replacements
    # (home/shell.nix), and `blesh` is bash's syntax-highlighting/
    # autosuggestion engine sourced directly by store path there - listed
    # here too so its own helper commands are on PATH for manual use.
    ripgrep
    fd
    jq
    bat
    eza
    blesh
    # Scans a repo for anything that looks like a committed secret -
    # `gitleaks detect --source . -v` - the practical backstop for
    # "keeping credentials out of git history" (README) alongside a
    # project's own .gitignore and reviewing `git diff --staged`.
    gitleaks

    # Additional ported utilities (spec 015) general-purpose enough to
    # stay in every profile: a plain HTTP fetcher, a directly-runnable
    # `rclone` (also used internally by pkgs/sensitivectl), and changelog
    # generation. gopass/deno moved to the agent-ops persona in a
    # newbie-simplification pass, since they're more specialized.
    wget
    rclone
    git-chglog

    # Lefthook git hooks manager (spec 016) - a no-op until a project
    # actually adds a lefthook.yml, so it stays available to everyone.
    # See templates/lefthook.yml.example.
    lefthook
  ]);
}
