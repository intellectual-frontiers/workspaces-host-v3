#!/bin/sh
# Entrypoint for the sandboxed OCI image: runs as root just long enough to
# apply the network-egress allowlist (needs CAP_NET_ADMIN/CAP_NET_RAW),
# then drops to the non-root "agent" user for the actual workload -
# mirroring Anthropic's reference Claude Code devcontainer firewall
# (non-root execution + restricted egress).
set -eu

if [ "${SKIP_FIREWALL:-}" != "1" ]; then
    init-firewall
else
    echo "sandboxed-entrypoint: SKIP_FIREWALL=1 set - running with unrestricted egress" >&2
fi

if [ $# -eq 0 ]; then
    set -- bash -l
fi

exec setpriv --reuid=agent --regid=agent --clear-groups --inh-caps=-all "$@"
