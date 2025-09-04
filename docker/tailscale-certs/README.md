# Tailscale Cert Quick Command

Generate the cert and key with fixed names (`cert.crt` / `cert.key`) in one step:

    tailscale cert --cert-file cert.crt --key-file cert.key YOUR-DOMAIN.ts.net

---

## Mounting Certs into Docker

When using the certs with Docker (e.g., Nginx), you must mount the directory where they are stored as an **absolute path on your host**:

    volumes:
      - /absolute/path/to/docker/tailscale-certs:/etc/nginx/certs:ro # absolute path – see [docs](www)
[text](../rustdesk)
### Path Examples

| OS      | Example Path                                    |
|---------|-------------------------------------------------|
| Linux   | `/home/username/docker/tailscale-certs`         |
| Windows | `C:/Users/YourName/docker/tailscale-certs`      |

> Replace `/absolute/path/to/docker/tailscale-certs` with the actual full path where your certs are stored.
