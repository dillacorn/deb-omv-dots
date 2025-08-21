# Guide: Installing a Custom Hugging Face Model into Ollama

This guide explains how to run custom AI models from Hugging Face in Ollama.

---

## File Format Problem

Most models on Hugging Face use "safetensors" (.safetensors files), but Ollama only works with "GGUF" (.gguf files). You need to find or convert your model to GGUF format.

---

## Step 1: Find a GGUF Version

Look for a repository with "-GGUF" in the name, or search for "[model name] GGUF" on Hugging Face.

**Example:**
- Original: `microsoft/DialoGPT-medium`
- GGUF version: `mradermacher/DialoGPT-medium-GGUF`

Look for files ending in `.gguf`:
```
model-name.Q4_K_S.gguf  (smaller, faster)
model-name.Q5_K_S.gguf  (medium size/quality)
model-name.Q8_0.gguf    (largest, best quality)
```

---

## Step 2: Create a Modelfile

Create a text file called `Modelfile` with:

```dockerfile
FROM hf.co/mradermacher/Llama-3.2-3B-Instruct-GGUF:Llama-3.2-3B-Instruct.Q5_K_S.gguf

TEMPLATE """{{ if .System }}<|system|>
{{ .System }}{{ end }}{{ if .Prompt }}<|user|>
{{ .Prompt }}{{ end }}{{ if .Response }}<|assistant|>
{{ .Response }}{{ end }}"""

PARAMETER temperature 0.7
```

---

## Step 3: Docker Setup (if using Docker)

```yaml
services:
  ollama:
    image: ollama/ollama
    container_name: ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ./ollama-data:/root/.ollama
      - ./my-model:/root/.ollama/models/my-model
```

Put your `Modelfile` in the `./my-model/` folder.

---

## Step 4: Install Your Model

**Docker:**
```bash
docker exec -it ollama ollama create my-model -f /root/.ollama/models/my-model/Modelfile
```

**Native Ollama:**
```bash
ollama create my-model -f /path/to/your/Modelfile
```

---

## Step 5: Run Your Model

**Docker:**
```bash
docker exec -it ollama ollama run my-model
```

**Native Ollama:**
```bash
ollama run my-model
```

---

## Converting to GGUF (if no GGUF version exists)

1. **Install llama.cpp:**
   ```bash
   git clone https://github.com/ggerganov/llama.cpp
   cd llama.cpp
   make
   ```

2. **Download original model:**
   ```bash
   git lfs install
   git clone https://huggingface.co/username/model-name
   ```

3. **Convert:**
   ```bash
   python convert-hf-to-gguf.py ./model-name --outfile model-name.gguf
   ```

4. **Update Modelfile:**
   ```dockerfile
   FROM ./model-name.gguf
   ```

---

## Private/Gated Models

```bash
export HUGGING_FACE_HUB_TOKEN=your_token_here
```

Then run your ollama create command.

---

## Useful Commands

```bash
ollama list                    # List models
ollama rm model-name          # Remove model
ollama show model-name        # Model details
```

---

## Troubleshooting

**"Model not found"** - Check GGUF file path in Modelfile

**"Out of memory"** - Use smaller quantization (Q4_K_S instead of Q8_0)

**"Invalid model format"** - Make sure you're using .gguf, not .safetensors

**Weird responses** - Adjust TEMPLATE in Modelfile for your model's format
