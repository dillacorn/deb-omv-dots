# Guide: Installing a Custom Hugging Face Model into Ollama

This guide explains how to run custom models from Hugging Face in [Ollama](https://ollama.ai).  
Ollama does **not** run PyTorch safetensors directly — you need **GGUF** format.

---

## 1. Requirements

- Running Ollama (native or in Docker)
- Mounted volume for `/root/.ollama`
- [Docker Compose](https://docs.docker.com/compose/) if using containers

---

## 2. Ollama Model Requirements

Ollama can only run models in **GGUF** format.  
Typical Hugging Face repos provide `.safetensors`, which are incompatible.

You must either:
- Find a **GGUF mirror** of the model on Hugging Face, or  
- Convert the model yourself.

---

## 3. Finding a GGUF Repo

Many popular models already have GGUF versions. For example:
```
hf.co/mradermacher/Llama-3.2-3B-Instruct-GGUF
```

Check the files for quantized `.gguf` models:
```
Llama-3.2-3B-Instruct.Q4_K_S.gguf
Llama-3.2-3B-Instruct.Q5_K_S.gguf
```

---

## 4. Creating a Modelfile

Ollama uses a **Modelfile** to define the model. Example:

```dockerfile
FROM hf.co/mradermacher/Llama-3.2-3B-Instruct-GGUF:Llama-3.2-3B-Instruct.Q5_K_S.gguf

TEMPLATE """{{ if .System }}<|system|>
{{ .System }}{{ end }}{{ if .Prompt }}<|user|>
{{ .Prompt }}{{ end }}{{ if .Response }}<|assistant|>
{{ .Response }}{{ end }}"""

PARAMETER temperature 0.7
```

- `FROM` must point to a `.gguf` file.
- `TEMPLATE` defines prompt formatting (optional).
- `PARAMETER` sets default runtime parameters (optional).

---

## 5. Docker Volume Setup

In `docker-compose.yml`, mount a directory for custom models:

```yaml
services:
  ollama:
    image: ollama/ollama:rocm
    container_name: ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ./ollama:/root/.ollama
      - ./custom-model:/root/.ollama/models/custom-model
    devices:
      - /dev/kfd
      - /dev/dri
```

Now place your Modelfile at:
```bash
./custom-model/Modelfile
```

---

## 6. Build the Model

Inside the running container, build the model:

```bash
docker exec -it ollama ollama create custom-model -f /root/.ollama/models/custom-model/Modelfile
```

Verify:
```bash
docker exec -it ollama ollama list
docker exec -it ollama ollama show custom-model
```

---

## 7. Run the Model

```bash
docker exec -it ollama ollama run custom-model
```

---

## 8. Private or Gated Models

- If the Hugging Face repo is **public**: no token is required.
- If the repo is **private or gated**, set a token:

```bash
export HUGGING_FACE_HUB_TOKEN=your_token_here
```

Then rebuild the model.

---

## 9. Converting Models to GGUF (if no GGUF exists)

If the Hugging Face repo has only `.safetensors`:

1. **Clone the model:**
   ```bash
   git lfs install
   git clone https://huggingface.co/<user>/<model>
   ```

2. **Convert with llama.cpp:**
   ```bash
   python convert-hf-to-gguf.py --model <path-to-model> --outfile mymodel.gguf
   ```

3. **Place `mymodel.gguf`** into your mounted volume or upload to your own Hugging Face repo.

4. **Update your Modelfile:**
   ```dockerfile
   FROM ./mymodel.gguf
   ```

5. **Rebuild** with `ollama create`.

---

## 10. Summary

- Ollama only runs **GGUF** models.
- Use **Modelfile** → `ollama create` → `ollama run`.
- **Public** GGUF repos need no token.
- **Private** repos require `HUGGING_FACE_HUB_TOKEN`.
- If no GGUF exists, **convert it** with llama.cpp.

---

## Troubleshooting

### Common Issues:
- **"Model not found"**: Ensure the GGUF file path in your Modelfile is correct
- **"Permission denied"**: Check Docker volume mounts and file permissions
- **"Out of memory"**: Try a smaller quantized model (Q4_K_S instead of Q5_K_S)
- **"Invalid model format"**: Verify you're using a `.gguf` file, not `.safetensors`

### Useful Commands:
```bash
# List all models
docker exec -it ollama ollama list

# Remove a model
docker exec -it ollama ollama rm model_name

# Check model info
docker exec -it ollama ollama show model_name

# Pull official models
docker exec -it ollama ollama pull llama2
```