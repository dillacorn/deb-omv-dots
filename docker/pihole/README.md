This allows user to have tailscale addresses point back to local address on the local network.. Meaning tailscale is no longer required for local network.

Pretty freaking cool.. follow pictures for setup.

I may add blocklists I like to use in pihole in the future.

## How to access
Your tailscale magicDNS address

example:
https://MACHINE.MagicDNS-example.ts.net:8089

## ⚙️ Configure `compose.yml` for Tailscale certs

This service expects TLS certs to be mounted into the container. Use an **absolute path** on your host. Details and folder layout:  
[deb-omv-dots/docker/tailscale-certs](https://github.com/dillacorn/deb-omv-dots/tree/main/docker/tailscale-certs)
