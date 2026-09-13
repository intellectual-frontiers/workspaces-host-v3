#!/usr/bin/env bash
# SessionStart hook: a minimal readiness check for a workspaces-host-v3
# provisioned project. Wired in via .claude/settings.json's `hooks.SessionStart`.
set -euo pipefail

echo "workspaces-host: session-start check"

if command -v nix >/dev/null 2>&1; then
    echo "  nix: $(nix --version)"
else
    echo "  nix: not found on PATH (install it before running 'nix develop' / 'home-manager switch')"
fi

if [ -f flake.nix ]; then
    echo "  flake.nix: present"
    if command -v nix >/dev/null 2>&1; then
        if nix flake metadata --no-write-lock-file >/dev/null 2>&1; then
            echo "  flake.lock: resolves"
        else
            echo "  flake.lock: does NOT resolve - run 'nix flake lock' or check network access"
        fi
    fi
else
    echo "  flake.nix: not present in $(pwd)"
fi

exit 0
