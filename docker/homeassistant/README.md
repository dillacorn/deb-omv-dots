## How to access
Your tailscale magicDNS address

example:
https://MACHINE.MagicDNS-example.ts.net:8125

## ⚙️ Configure `compose.yml` for Tailscale certs

This service expects TLS certs to be mounted into the container. Use an **absolute path** on your host. Details and folder layout:  
[deb-omv-dots/docker/tailscale-certs](https://github.com/dillacorn/deb-omv-dots/tree/main/docker/tailscale-certs)

#
#
#

# RING cameras stream fix

#### git clone patch:
```bash
git clone --depth=1 https://github.com/TeejMcSteez/HAWebRTCFix custom_components/ring
```

#### Restart homeassistant so it loads the custom component + installs its deps
```bash
docker restart homeassistant
custom_components/ring
```