#!/usr/bin/env bash
# /docker/tailscale-certs/renew.sh
# Renew Tailscale cert and optionally restart defined Compose stacks.

set -euo pipefail

DOMAIN="YOUR-DOMAIN.ts.net"
CERT_DIR="/docker/tailscale-certs"
TAILSCALE_BIN="/usr/bin/tailscale"  # verify with: which tailscale

RESTART_SCRIPT="/docker/restart_defined_compose.sh"
RUN_RESTART=1  # 0 to disable

cd "$CERT_DIR" \
  && "$TAILSCALE_BIN" cert --cert-file cert.crt --key-file cert.key "$DOMAIN" \
  && chown 1000:1000 cert.crt cert.key \
  && chmod 640 cert.crt cert.key

if [ "$RUN_RESTART" -eq 1 ]; then
  if [ -x "$RESTART_SCRIPT" ]; then
    "$RESTART_SCRIPT"
  else
    echo "restart script not found or not executable: $RESTART_SCRIPT"
  fi
fi
