this app was previously named "hoarder-app" but the dev had to change to "karakeep-app" due to legal issues

## How to access
Your tailscale magicDNS address

example:
https://MACHINE.MagicDNS-example.ts.net:5010

## ⚙️ Configure `compose.yml` for Tailscale certs

This service expects TLS certs to be mounted into the container. Use an **absolute path** on your host. Details and folder layout:  
[deb-omv-dots/docker/tailscale-certs](https://github.com/dillacorn/deb-omv-dots/tree/main/docker/tailscale-certs)
