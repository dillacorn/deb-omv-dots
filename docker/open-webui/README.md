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
