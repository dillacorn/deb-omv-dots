# Heavy modification required

Example:

Pi-hole points `flame.time-puffin.ts.net` to your local server IP.  
Then nginx on that server forwards the request to Flame’s Tailscale IP and returns the page to the device.

## What must be changed

Everything in `conf.d/*` must be edited to match:

- your service name
- your Tailscale MagicDNS address
- your service's Tailscale IP
- the correct certificate path for that service

Rename `compose_example.yml` to `compose.yml` or `docker-compose.yml` before using it.

In `compose.yml`:
- under `FTLCONF_dns_hosts`, add your local server IP followed by the service's MagicDNS hostname
- under the nginx `volumes`, add a read-only mount for that service’s Tailscale certificate directory

Example `FTLCONF_dns_hosts` entry:

```text
192.168.68.2 flame.time-puffin.ts.net
```

Example nginx cert volume:

```text
- /docker/flame/ts/state/certs:/etc/nginx/flame-certs:ro
```