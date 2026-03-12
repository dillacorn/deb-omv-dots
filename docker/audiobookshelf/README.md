## Access
Open the service in a browser using its Tailscale address:

https://<service>.<your-tailnet>.ts.net

Example:
https://audiobookshelf.time-puffin.ts.net

## Export certs
Only needed for local reverse proxy setups.

```bash
docker exec -it tailscale-<service> tailscale cert <service>.<your-tailnet>.ts.net
```

Example:
docker exec -it tailscale-audiobookshelf tailscale cert audiobookshelf.time-puffin.ts.net