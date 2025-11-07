# Tailscale Cert Quick Command (enter your magic DNS address in command)

Generate the cert and key with fixed names (`cert.crt` / `cert.key`) in one step:

    tailscale cert --cert-file cert.crt --key-file cert.key YOUR-DOMAIN.ts.net

## (all-in-one) tailscale cert command with ownership fix (enter your magic DNS address in command)

    cd /docker/tailscale-certs && tailscale cert --cert-file cert.crt --key-file cert.key YOUR-DOMAIN.ts.net && chown 1000:1000 cert.crt cert.key && chmod 640 cert.crt cert.key


---

## Mounting Certs into Docker (guide)

When using the certs with Docker (e.g., Nginx), you must mount the directory where they are stored as an **absolute path on your host**:

    volumes:
      - /absolute/path/to/docker/tailscale-certs:/etc/nginx/certs:ro # absolute path

### Path Examples

| OS      | Example Path                                    |
|---------|-------------------------------------------------|
| Linux   | `/home/username/docker/tailscale-certs`         |
| Windows | `C:/Users/YourName/docker/tailscale-certs`      |

> Replace `/absolute/path/to/docker/tailscale-certs` with the actual full path where your certs are stored.
