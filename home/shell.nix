{ config, lib, pkgs, ... }:

{
  # Where workspaces-host-v3 itself is cloned - used by
  # `workspaces-host-update`. Dotted (~/.workspaces-host-v3) so it stays
  # out of the way of a plain `ls`/directory listing in $HOME. Override
  # this in `home.sessionVariables` in a wrapping module if cloned
  # elsewhere.
  home.sessionVariables.WORKSPACES_HOST_REPO = "${config.home.homeDirectory}/.workspaces-host-v3";

  programs.bash = {
    enable = true;

    shellAliases = {
      ll = "eza -lah --git";
      ls = "eza";
      cat = "bat --paging=never";
      g = "git";
      # Deno aliases (spec 015) - "-A" grants every permission, the same
      # blanket default v1 used for its own `deno-run`/`deno-test`.
      deno-run = "deno run -A";
      deno-test = "deno test -A";
      # cd to the current git repo's top-level directory (spec 015).
      cdp = "cd $(git rev-parse --show-toplevel)";
    };

    # Fish's own signature interactive niceties - syntax highlighting,
    # autosuggestions from history - come from `blesh` (Bash Line Editor)
    # here instead, so bash gets the same feel without giving up
    # anything POSIX/bash-compatible tutorials and copy-pasted snippets
    # already assume. `mkOrder` controls where in the final ~/.bashrc
    # each piece lands: ble.sh's own docs require it be sourced before
    # anything else that touches readline/PROMPT_COMMAND (oh-my-posh,
    # zoxide, fzf below), with `ble-attach` itself deferred to the very
    # end - printing to stdout after attaching corrupts the prompt.
    initExtra = lib.mkMerge [
      (lib.mkOrder 5 ''
        # home-manager's own PATH/session-variable exports
        # (~/.nix-profile/etc/profile.d/hm-session-vars.sh, sourced from
        # ~/.profile) only take effect in a *login* shell - some
        # terminals (including, inconsistently, some WSL/Windows
        # Terminal configurations) start a new window as a non-login
        # interactive shell instead, which reads only this file and
        # never touches ~/.profile. Sourcing it here too, guarded by its
        # own $__HM_SESS_VARS_SOURCED check (so this is a no-op if a
        # login shell already ran it), means `doctor`/`ws-repos`/every
        # other tool this profile installs is on PATH in *any* new
        # shell, not just ones that happen to count as "login."
        if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
          . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
        fi
      '')

      (lib.mkOrder 10 ''
        source ${pkgs.blesh}/share/blesh/ble.sh --attach=none
      '')

      ''
        # Once a day, if $WORKSPACES_HOST_REPO is a real clone, check (in
        # the background, so shell startup is never blocked or slowed by
        # a network call) whether origin/main has moved and nudge the
        # engineer to run workspaces-host-update - informational only,
        # it never runs git pull/home-manager switch itself.
        if [ -d "$WORKSPACES_HOST_REPO/.git" ]; then
          state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/workspaces-host"
          stamp="$state_dir/last-update-check"
          mkdir -p "$state_dir"
          today=$(date +%Y-%m-%d)
          last=""
          [ -f "$stamp" ] && last=$(cat "$stamp")
          if [ "$today" != "$last" ]; then
            echo "$today" >"$stamp"
            (
              git -C "$WORKSPACES_HOST_REPO" fetch --quiet origin main 2>/dev/null || exit 0
              behind=$(git -C "$WORKSPACES_HOST_REPO" rev-list --count HEAD..origin/main 2>/dev/null)
              if [ -n "$behind" ] && [ "$behind" != "0" ]; then
                echo "workspaces-host-v3: $behind commit(s) behind origin/main - run workspaces-host-update to pick up new features" >&2
              fi
            ) &
            disown
          fi
        fi
      ''

      ''
        # SSH agent auto-start (spec 015): once per login shell (never a
        # plain interactive subshell/terminal tab, which would otherwise
        # spawn a redundant agent on every new window), start an agent
        # and load the first private key found if none is loaded yet.
        # `ssh-add -l` exits 0 (has keys), 1 (agent running, no keys), or
        # 2 (no agent reachable) - distinguishing "nothing to do" from
        # "start one" from "just load the key" without parsing output.
        if shopt -q login_shell; then
          ssh_key=""
          for candidate in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa"; do
            if [ -f "$candidate" ]; then
              ssh_key="$candidate"
              break
            fi
          done
          if [ -n "$ssh_key" ]; then
            ssh-add -l >/dev/null 2>&1
            agent_status=$?
            if [ "$agent_status" = "2" ]; then
              eval "$(ssh-agent -s)" >/dev/null
              agent_status=1
            fi
            if [ "$agent_status" = "1" ]; then
              ssh-add "$ssh_key" >/dev/null 2>&1
            fi
          fi
        fi
      ''

      (lib.mkOrder 2000 ''
        [[ ! ''${BLE_VERSION-} ]] || ble-attach
      '')
    ];
  };

  # bash becomes the interactive shell for this profile without touching
  # /etc/shells or /etc/passwd here (home-manager standalone mode can't
  # manage either on its own) - install.sh does that separately, as a
  # best-effort `chsh` step once bash's own home-manager-pinned binary
  # exists on disk. It's the container entrypoint directly in the OCI
  # image instead (spec 005).

  programs.oh-my-posh = {
    enable = true;
    enableBashIntegration = true;
    settings = builtins.fromJSON (
      builtins.unsafeDiscardStringContext
        (builtins.readFile ../themes/oh-my-posh/coach.omp.json)
    ) // {
      # oh-my-posh's own binary here lives in the read-only Nix store, so
      # a self-upgrade would either fail or silently write a binary Nix
      # doesn't track - the opposite of Constitution Principle I. A newer
      # oh-my-posh means bumping this flake's nixpkgs pin instead.
      disable_notice = true;
    };
  };

  # Smarter `cd` (`z`/`zi`, frecency-ranked) and fuzzy history/file
  # search (Ctrl-R, Ctrl-T, Alt-C) - the closest bash equivalents to
  # conveniences fish either had built in or made trivial via a plugin.
  # Both are opt-in *commands* alongside the real `cd`, not replacements
  # for it.
  programs.zoxide.enable = true;

  programs.fzf = {
    enable = true;
    # fd instead of the default find(1)-based commands: faster, and
    # respects .gitignore by default.
    defaultCommand = "fd --type f --hidden --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
  };
}
