{ lib, ... }:

{
  # ~/workspaces is the governed root ws-repos (pkgs/ws-repos) clones/pulls
  # repos into, following the <git-host>/<org>/.../<repo> convention. The
  # directory and an empty repo-list config are created once, on first
  # activation, and never touched again on later activations - this is
  # per-user declared state (which repos to track), not something
  # home-manager should own or overwrite.
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
  '';
}
