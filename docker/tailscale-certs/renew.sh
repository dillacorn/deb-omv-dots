#!/usr/bin/env bash
# Renew a Tailscale-issued HTTPS cert and fix ownership/perms so containers
# can read it, then restart only nginx containers (name contains "nginx").

set -euo pipefail

# Directory where certs are stored and mounted into containers
CERT_DIR="/docker/tailscale-certs"

# Optional: restart nginx containers after renewal so they pick up new certs
RESTART_NGINX=1  # set to 0 to disable automatic restarts

# Locate tailscale binary (works better than hardcoding for cron/root PATH quirks)
TAILSCALE_BIN="${TAILSCALE_BIN:-}"
if [ -z "${TAILSCALE_BIN}" ]; then
  TAILSCALE_BIN="$(command -v tailscale || true)"
fi
if [ -z "${TAILSCALE_BIN}" ] || [ ! -x "${TAILSCALE_BIN}" ]; then
  echo "tailscale CLI not found in PATH (set TAILSCALE_BIN if needed)." >&2
  exit 1
fi

# Auto-detect this machine's MagicDNS FQDN (Self.DNSName), strip trailing dot
if command -v python3 >/dev/null 2>&1; then
  DOMAIN="$("$TAILSCALE_BIN" status --self --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))')"
elif command -v jq >/dev/null 2>&1; then
  DOMAIN="$("$TAILSCALE_BIN" status --self --json | jq -r '.Self.DNSName' | sed 's/\.$//')"
else
  echo "Need python3 or jq to parse: tailscale status --self --json" >&2
  exit 1
fi

if [ -z "${DOMAIN}" ]; then
  echo "Failed to detect MagicDNS domain from tailscale status." >&2
  exit 1
fi

cd "$CERT_DIR" \
  && "$TAILSCALE_BIN" cert --cert-file cert.crt --key-file cert.key "$DOMAIN" \
  && chown 1000:1000 cert.crt cert.key \
  && chmod 640 cert.crt cert.key

if [ "$RESTART_NGINX" -eq 1 ]; then
  docker ps -q --filter "name=nginx" | xargs -r docker restart
fi
