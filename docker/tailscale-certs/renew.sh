#!/usr/bin/env bash
# /docker/tailscale-certs/renew.sh
# Renew Tailscale cert and fix ownership/perms for calibre container.

# make executable: chmod +x /docker/tailscale-certs/renew.sh

set -euo pipefail

DOMAIN="YOUR-DOMAIN.ts.net"
CERT_DIR="/docker/tailscale-certs"
TAILSCALE_BIN="/usr/bin/tailscale"  # find yours with: which tailscale | command -v tailscale | type -a tailscale

cd "$CERT_DIR" \
  && "$TAILSCALE_BIN" cert --cert-file cert.crt --key-file cert.key "$DOMAIN" \
  && chown 1000:1000 cert.crt cert.key \
  && chmod 640 cert.crt cert.key
