## How to access
Your tailscale magicDNS address

example:
https://MACHINE.MagicDNS-example.ts.net:7005

## ⚙️ Configure `compose.yml` for Tailscale certs

This service expects TLS certs to be mounted into the container. Use an **absolute path** on your host. Details and folder layout:  
[deb-omv-dots/docker/tailscale-certs](https://github.com/dillacorn/deb-omv-dots/tree/main/docker/tailscale-certs)

# Ollama Model Management (Docker)

**Browse Models**  
Go to: https://ollama.com/library

**Install Model**
```bash
docker exec -it ollama ollama pull <model:tag>
# Example:
docker exec -it ollama ollama pull qwen2.5-coder:7b-q4_K_M
```

- List Installed Models
```bash
docker exec -it ollama ollama list
```

- Uninstall Model
```bash
docker exec -it ollama ollama rm <model:tag>
# Cleanup unused data:
docker exec -it ollama ollama prune
```
