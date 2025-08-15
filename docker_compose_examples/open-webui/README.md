# Local Models with Ollama + Open WebUI (Docker)

Single-file README covering how to **browse**, **install**, **verify**, **use**, and **remove** models with your existing Docker stack.

Assumptions:
- Services: `ollama` (port `11434`) and `open-webui` (port `8080` → host `7005`).
- Commands run on the **host**; they exec into the `ollama` container.
- AMD GPUs use `ollama/ollama:rocm`; NVIDIA uses `ollama/ollama:latest`. Model management commands are identical.

---

## Browse Models (Find Names/Tags)

Primary index of official community models:
- https://ollama.com/library

Conventions:
- **Model name**: `name:variant` (e.g., `qwen2.5-coder:7b`).
- **Quantized tags** add a suffix (e.g., `qwen2.5-coder:7b-q4_K_M`).
- Smaller quant (q4_*) → lower VRAM/RAM and usually faster; slight quality tradeoff.

Examples you can search for in the library:
```text
qwen2.5-coder:7b-q4_K_M
llama3.1:8b-instruct-q4_K_M
deepseek-coder:6.7b-instruct-q4_K_M
phi3:3.8b-mini-instruct-q4_K_M
starcoder2:7b-q4_K_M
```

Optional: peek model metadata without committing (if present in registry):
```bash
docker exec -it ollama ollama show qwen2.5-coder:7b-q4_K_M
```

---

## Install (Pull) Models

Install a specific quantized tag:
```bash
docker exec -it ollama ollama pull qwen2.5-coder:7b-q4_K_M
```

Install a base/full-precision variant (bigger/slower):
```bash
docker exec -it ollama ollama pull qwen2.5-coder:7b
```

Install multiple common coder models at once:
```bash
for m in \
  qwen2.5-coder:7b-q4_K_M \
  deepseek-coder:6.7b-instruct-q4_K_M \
  llama3.1:8b-instruct-q4_K_M \
  phi3:3.8b-mini-instruct-q4_K_M
do
  docker exec -it ollama ollama pull "$m"
done
```

Force re-install (overwrite existing local copy):
```bash
docker exec -it ollama ollama pull --force qwen2.5-coder:7b-q4_K_M
```

---

## Verify What’s Installed

List locally installed models:
```bash
docker exec -it ollama ollama list
```

Show a model’s details (family, params, quant, size):
```bash
docker exec -it ollama ollama show qwen2.5-coder:7b-q4_K_M
```

Quick sanity run:
```bash
docker exec -it ollama ollama run qwen2.5-coder:7b-q4_K_M -p "Say hello."
```

---

## Use in Open WebUI

Open WebUI → **Settings → Connections**
- Base URL (Docker network): `http://ollama:11434`
- Or from host directly: `http://localhost:11434`

Select the model **exactly** as listed by `ollama list`, e.g.:
```text
qwen2.5-coder:7b-q4_K_M
```

Optional per-model parameters in Open WebUI → Model → Parameters:
```json
{
  "num_ctx": 2048,
  "num_batch": 512,
  "num_keep": 48,
  "num_predict": 512
}
```

---

## Remove Models (Free Space)

List first:
```bash
docker exec -it ollama ollama list
```

Remove one:
```bash
docker exec -it ollama ollama rm qwen2.5-coder:7b-q4_K_M
```

Remove many:
```bash
for m in qwen2.5-coder:7b llama3.1:8b-instruct-q4_K_M; do
  docker exec -it ollama ollama rm "$m"
done
```

Prune unreferenced/unused model blobs:
```bash
docker exec -it ollama ollama prune
```

Host-side quick disk check (models volume):
```bash
du -h -d1 ./ollama | sort -h
```

---

## Fast Switch: Full → Quantized

Replace full-precision with a smaller, faster quant:
```bash
docker exec -it ollama ollama rm qwen2.5-coder:7b
docker exec -it ollama ollama pull qwen2.5-coder:7b-q4_K_M
```

---

## One-Off Overrides (No Persist)

Test inference knobs without saving them as defaults:
```bash
docker exec -it ollama ollama run qwen2.5-coder:7b-q4_K_M \
  -p "Write a Python function to parse an nginx access log line." \
  -o num_ctx=2048 -o num_batch=512 -o num_predict=256
```

---

## GPU Notes

NVIDIA (CUDA):
```yaml
# image: ollama/ollama:latest
# Docker must be configured with NVIDIA runtime; host needs nvidia drivers + nvidia-container-toolkit
```

AMD (ROCm):
```yaml
# image: ollama/ollama:rocm
# devices: /dev/kfd and /dev/dri must be passed; user typically in 'video,render' groups
# many RDNA2/3 cards benefit from:
# environment:
#   - HSA_OVERRIDE_GFX_VERSION=10.3.0   # RX 6800 XT example
```

Confirm model actually uses GPU (look for ROCm/CUDA and offload lines):
```bash
docker logs -n 200 ollama
```

---

## Troubleshooting

Tag not found:
```text
Check spelling and the library page. Use a valid tag like -q4_K_M.
```

Very slow or OOM:
```text
Switch to a smaller quant (q4_K_M), reduce num_ctx/num_batch, or pick a smaller model (e.g., 3B).
```

GPU not used (AMD):
```text
Use image :rocm, pass /dev/kfd and /dev/dri, ensure groups video/render, set HSA_OVERRIDE_GFX_VERSION if needed.
```

GPU not used (NVIDIA):
```text
Install nvidia driver + nvidia-container-toolkit, set Docker runtime to NVIDIA, restart Docker.
```

---

## CLI Reference (Ollama)

```text
ollama pull <name[:tag]>            # download/install model
ollama list                         # list local models
ollama show <name[:tag]>            # show metadata
ollama run <name[:tag]> [-p ..]     # run a prompt
ollama rm <name[:tag]>              # remove model
ollama prune                        # prune unused data
```
