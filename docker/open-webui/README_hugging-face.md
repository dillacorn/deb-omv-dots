# Guide: Installing a Custom Hugging Face Model into Ollama

---

## Step 1: Find a GGUF Model

Find a model with "-GGUF" in the name on Hugging Face. Look for `.gguf` files like:
```
model-name.Q4_K_S.gguf  (smaller, faster)
model-name.Q5_K_S.gguf  (medium)
model-name.Q8_0.gguf    (largest, best quality)
```

---

## Step 2: Create a Modelfile

Create a file called `Modelfile` (no extension) with:

```dockerfile
FROM hf.co/mradermacher/Llama-3.2-3B-Instruct-GGUF:Llama-3.2-3B-Instruct.Q5_K_S.gguf

TEMPLATE """{{ if .System }}<|system|>
{{ .System }}{{ end }}{{ if .Prompt }}<|user|>
{{ .Prompt }}{{ end }}{{ if .Response }}<|assistant|>
{{ .Response }}{{ end }}"""

PARAMETER temperature 0.7
```

---

## Step 3: Create the Model

```bash
docker exec -it ollama ollama create custom-model -f /root/.ollama/models/custom-model/Modelfile
```

---

## Step 4: Run the Model

```bash
docker exec -it ollama ollama run custom-model
```

---

## That's it.

---

## If No GGUF Version Exists

Convert it yourself:
```bash
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
make
git lfs install
git clone https://huggingface.co/username/model-name
python convert-hf-to-gguf.py ./model-name --outfile model-name.gguf
```

Then use `FROM ./model-name.gguf` in your Modelfile.

---

## Private Models

```bash
export HUGGING_FACE_HUB_TOKEN=your_token_here
```

---

## Useful Commands

```bash
ollama list                    # List models
ollama rm model-name          # Remove model
ollama show model-name        # Model details
```
