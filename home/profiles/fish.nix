{ ... }:

{
  # An alternative interactive shell (spec 014) for anyone who finds
  # blesh's default keystroke-time completion noticeably slow (see the
  # docs site's "Autocomplete UX" section) and would rather have fish's
  # own native, Rust-implemented (fish 4.x) syntax highlighting and
  # autosuggestions instead of bash-plus-blesh. Purely additive, like
  # every other persona: this only makes `fish` and its own config
  # available. It never touches your login shell - home-manager can't
  # do that anyway (it doesn't write /etc/passwd) - so trying it, or
  # making it permanent with `chsh`, stays a separate, deliberate step
  # (Constitution Principle III's "a deliberate, separate, human
  # action," the same category as joining a Tailscale mesh).
  #
  # oh-my-posh, zoxide, fzf, and direnv (home/shell.nix, home/direnv.nix)
  # all auto-detect an enabled `programs.fish` and wire themselves in on
  # their own (home-manager's home.shell.enableShellIntegration default
  # is true) - nothing extra to configure here for any of them.
  programs.fish = {
    enable = true;

    # Mirrors home/shell.nix's bash aliases exactly, so switching shells
    # doesn't also mean relearning muscle memory.
    shellAliases = {
      ll = "eza -lah --git";
      ls = "eza";
      cat = "bat --paging=never";
      g = "git";
      deno-run = "deno run -A";
      deno-test = "deno test -A";
    };

    # cdp needs real command substitution ($(...) in bash is (...) in
    # fish), so it's a function rather than a plain alias like the ones
    # above.
    functions = {
      cdp = "cd (git rev-parse --show-toplevel)";
    };

    # Fish equivalent of the same daily nudge in home/shell.nix's bash
    # initExtra, kept in behavioral sync with it - checked directly
    # against a real fish 4.0.8 build rather than translated blind:
    # fish's `exit` inside a backgrounded `begin ... end &` terminates
    # the whole interactive session, not just that job (unlike bash's
    # `(...)&`, which forks a real subshell), so this uses an `if`
    # guard instead of bash's early-exit style. `disown` isn't used
    # either - tested directly, and unlike bash it raced with fish's own
    # job bookkeeping and printed a spurious "no suitable jobs" error at
    # every shell start for no behavioral benefit (the job runs to
    # completion and reports nothing back to the prompt either way).
    interactiveShellInit = ''
      if test -d "$WORKSPACES_HOST_REPO/.git"
        set -l state_dir $XDG_STATE_HOME
        test -z "$state_dir"; and set state_dir "$HOME/.local/state"
        set state_dir "$state_dir/workspaces-host"
        set -l stamp "$state_dir/last-update-check"
        mkdir -p "$state_dir"
        set -l today (date +%Y-%m-%d)
        set -l last ""
        test -f "$stamp"; and set last (cat "$stamp")
        if test "$today" != "$last"
          echo "$today" >"$stamp"
          begin
            if git -C "$WORKSPACES_HOST_REPO" fetch --quiet origin main 2>/dev/null
              set -l behind (git -C "$WORKSPACES_HOST_REPO" rev-list --count HEAD..origin/main 2>/dev/null)
              if test -n "$behind"; and test "$behind" != "0"
                echo "workspaces-host-v3: $behind commit(s) behind origin/main - run workspaces-host-update to pick up new features" >&2
              end
            end
          end &
        end
      end
    '';

    # loginShellInit already scopes this to login shells only (fish's
    # own equivalent of bash's `shopt -q login_shell` guard), so no
    # extra check is needed here. ssh-agent's default `-s` output is
    # Bourne-shell syntax fish can't `eval`; `-c` (csh-style: `setenv
    # NAME value;`) gets parsed line by line instead - verified against
    # a real ssh-agent -c build, not assumed.
    loginShellInit = ''
      set -l ssh_key ""
      for candidate in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa"
        if test -f "$candidate"
          set ssh_key "$candidate"
          break
        end
      end
      if test -n "$ssh_key"
        ssh-add -l >/dev/null 2>&1
        set -l agent_status $status
        if test "$agent_status" = 2
          for line in (ssh-agent -c)
            switch $line
              case "setenv SSH_AUTH_SOCK *;"
                set -gx SSH_AUTH_SOCK (echo $line | string replace -r '^setenv SSH_AUTH_SOCK (\S+);$' '$1')
              case "setenv SSH_AGENT_PID *;"
                set -gx SSH_AGENT_PID (echo $line | string replace -r '^setenv SSH_AGENT_PID (\S+);$' '$1')
            end
          end
          set agent_status 1
        end
        if test "$agent_status" = 1
          ssh-add "$ssh_key" >/dev/null 2>&1
        end
      end
    '';
  };
}
