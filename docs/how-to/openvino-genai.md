# OpenVINO GenAI Runtime (Dataxis Sheet)

This playbook captures the end-to-end workflow for running LLM inference with OpenVINO GenAI, Ollama, and Hugging Face from this dotfiles stack.

## Dataxis Snapshot

| Signal | Value | Notes |
| --- | --- | --- |
| OS | Ubuntu 24.04.3 LTS (WSL2) | `uname -a` → Linux Yoga7i 6.6.87.2-microsoft-standard-WSL2 |
| CPU | Intel® Core™ Ultra 5 226V (8 cores) | AVX2 + AVX-VNNI available (see `lscpu`) |
| GPU | Not detected inside WSL2 | Install Windows host drivers + enable GPU passthrough if needed |
| Python | 3.12.3 | System + venv share the same interpreter |
| Venv | `/opt/openvino-genai/venv` | Curated CPU-only stack (OpenVINO 2024.6, torch 2.4.1+cpu, pinned deps) |
| Disk | 938 GB free on `/` | Plenty of space for model caches |
| Ollama | Not installed | Run the Windows host installer or Linux binary as needed |

## Provision Checklist

### 0. Turn-key bootstrap (recommended)

Run the automated setup once to create the shared virtualenv, install a curated (and version-pinned) package stack, and snapshot dependencies:

```zsh
just openvino-setup
```

Pass `--dry-run` to preview or `--no-freeze` if you do not want to update `docs/reference/openvino-genai/requirements.lock` yet. Custom locations are supported, for example:

```zsh
just openvino-setup -- --venv "$HOME/.virtualenvs/openvino" --models "$HOME/models/openvino" --cache "$HOME/.cache/huggingface"
```

The script pins OpenVINO packages to the 2024.6 line (for Python 3.12 compatibility), installs the Python Ollama client (`ollama`), and checks the Ollama service. If the CLI is installed but the daemon is offline, it will remind you to start it.

1. **Populate the shared virtual environment** (runs under zsh/bash):

   ```zsh
   openvino_genai_activate || source /opt/openvino-genai/venv/bin/activate
   python -m pip install --upgrade pip setuptools wheel
   pip install --index-url https://download.pytorch.org/whl/cpu "torch==2.4.1"
   pip install \
     numpy==1.26.4 \
     openvino==2024.6.0 \
     openvino-dev==2024.6.0 \
     openvino-genai==2024.6.0.0 \
     openvino-tokenizers==2024.6.0.0 \
     optimum-intel==1.15.0 \
     optimum==1.27.0 \
     transformers==4.56.2 \
     accelerate==1.10.1 \
     huggingface-hub==0.35.1 \
     pillow==11.3.0 \
     fastapi==0.117.1 \
     uvicorn==0.37.0 \
     rich==14.1.0 \
     ollama==0.6.0 \
     datasets==4.1.1 \
     scipy==1.16.2 \
     psutil==7.1.0 \
     sentencepiece==0.2.1
   ```

   The automation script removes any stray CUDA wheels and keeps the environment CPU-friendly by default. Add optional adapters (LoRA, PEFT, etc.) after provisioning if needed.

2. **Optional acceleration** – if you want GPU or NPU offload, install the Intel® drivers on Windows, enable WSL GPU support, then add `intel-gpu-tools` inside WSL. Verify with `clinfo` / `ovc_info`.

3. **Model storage layout** – use the defaults exported by the loader:
   - `$OPENVINO_GENAI_MODELS_DIR` → `/opt/openvino-genai/models`
   - `$HUGGINGFACE_HUB_CACHE` → `/opt/openvino-genai/cache`

   Create the folders if they do not exist:

   ```zsh
   sudo mkdir -p /opt/openvino-genai/{models,cache}
   sudo chown -R "$USER" /opt/openvino-genai
   ```

4. **Ollama service** – install and launch Ollama on the Windows host (recommended) or in WSL:
   - Windows: install from <https://ollama.com/download>, ensure the service is running.
   - WSL: `curl -fsSL https://ollama.com/install.sh | sh && sudo systemctl enable --now ollama` (requires Systemd-enabled WSL).
   Export `OLLAMA_HOST` in `.env` if you access a remote instance.

## Daily Commands

These helpers are now available everywhere:

| Usage | Command | Description |
| --- | --- | --- |
| Activate venv | `openvino_genai_activate` | Sources `bin/activate` only when needed |
| Exit venv | `openvino_genai_deactivate` | Wrapper around `deactivate` |
| Run Python | `openvino_genai_python script.py` | Ensures the venv is active before running |
| Run pip | `openvino_genai_pip install package` | Uses the shared environment |
| Quick status | `openvino_genai_info` | Prints venv path, Python version, Ollama detection |
| Just status | `just openvino-info` | Shell-agnostic status report |
| Just wrapper | `just openvino-python --version` | Executes inside the venv |
| Pip wrapper | `just openvino-pip list` | Runs `pip` safely in the venv |
| Freeze deps | `just openvino-freeze-reqs` | Writes `docs/reference/openvino-genai/requirements.lock` |

Override the install path when needed by exporting `OPENVINO_GENAI_VENV` (and matching directories) in `.env` or `.envrc`.

## Model Intake

### Hugging Face

```zsh
openvino_genai_activate
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download(
   repo_id="meta-llama/Llama-3-8b",
   local_dir="$OPENVINO_GENAI_MODELS_DIR/llama-3-8b",
   local_dir_use_symlinks=False,
)
PY
```

Convert the weights with Optimum-Intel or the OpenVINO CLI:

```zsh
openvino_genai_python -m optimum.exporters.openvino.convert \
   --model "$OPENVINO_GENAI_MODELS_DIR/llama-3-8b" \
   --task text-generation \
   --output "$OPENVINO_GENAI_MODELS_DIR/llama-3-8b-openvino"
```

### Ollama

```zsh
# Pull an upstream model on the Ollama host
ollama pull mistral:latest

# Or register your converted OpenVINO assets with a Modelfile
cat <<'EOF' > "$OPENVINO_GENAI_MODELS_DIR/mistral/Modelfile"
FROM mistral
PARAMETER num_ctx 4096
EMBEDDING /models/mistral-openvino
EOF
ollama create mistral-openvino -f "$OPENVINO_GENAI_MODELS_DIR/mistral/Modelfile"
```

Drive Ollama from Python inside the venv:

```zsh
openvino_genai_python - <<'PY'
import ollama
resp = ollama.chat(model="mistral-openvino", messages=[{"role": "user", "content": "Hello"}])
print(resp["message"]["content"].strip())
PY
```

## Validation & Smoke Tests

1. **Environment sanity**

   ```zsh
   openvino_genai_info
   just openvino-info
   just openvino-python --version
   just openvino-pip list
   ```

2. **OpenVINO runtime probe**

   ```zsh
   openvino_genai_python - <<'PY'
   from openvino_genai import TextGenerator
   print(TextGenerator.__name__)
   PY
   ```

3. **Benchmark hook (optional)** – once models are ready, store quick latency metrics under `docs/reference/openvino-genai/benchmarks.md`.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `OpenVINO GenAI activate script not found` | Verify `/opt/openvino-genai/venv` exists or update `OPENVINO_GENAI_VENV`. |
| `ollama: command not found` | Install Ollama on Windows or WSL and add it to your `PATH`. |
| Slow downloads from Hugging Face | Confirm `$HUGGINGFACE_HUB_CACHE` points to a fast disk and run `huggingface-cli login` once. |
| GPU not visible | Install GPU drivers on Windows and enable WSL CUDA/DirectML, then re-run `openvino_genai_info`. |

## Next Steps

- Populate the venv and freeze dependencies with `just openvino-freeze-reqs`.
- Commit the generated requirements lock and any benchmark notes under `docs/reference/openvino-genai/`.
- Consider adding direnv policies to auto-activate the venv only in OpenVINO project directories.
