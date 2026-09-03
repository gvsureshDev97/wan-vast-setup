#!/bin/bash
set -e

echo "=========================================="
echo " IndicF5 Telugu TTS - RTX 5090 Setup"
echo "=========================================="

cd /workspace

# ============================================================
# 1. GPU CHECK
# ============================================================

echo ""
echo "[1/7] Checking GPU..."

nvidia-smi --query-gpu=name,memory.total --format=csv,noheader

# ============================================================
# 2. PYTHON ENVIRONMENT
# ============================================================

echo ""
echo "[2/7] Creating Python environment..."

if [ ! -d "/workspace/indicf5_env" ]; then
    python3 -m venv /workspace/indicf5_env
fi

source /workspace/indicf5_env/bin/activate

python -m pip install --upgrade pip setuptools wheel

# ============================================================
# 3. PYTORCH
# ============================================================

echo ""
echo "[3/7] Installing PyTorch..."

pip install \
    torch==2.11.0 \
    torchvision==0.26.0 \
    torchaudio==2.11.0 \
    --index-url https://download.pytorch.org/whl/cu128

# ============================================================
# 4. INDICF5
# ============================================================

echo ""
echo "[4/7] Installing IndicF5..."

pip install git+https://github.com/ai4bharat/IndicF5.git

# ============================================================
# 5. HUGGING FACE LOGIN
# ============================================================

echo ""
echo "[5/7] Hugging Face authentication"
echo ""
echo "Make sure you have access to:"
echo "ai4bharat/IndicF5"
echo ""
echo "Run:"
echo "hf auth login"
echo ""

hf auth whoami || {
    echo ""
    echo "Please login to Hugging Face."
    hf auth login
}

# ============================================================
# 6. DOWNLOAD INDICF5
# ============================================================

echo ""
echo "[6/7] Downloading IndicF5..."

rm -rf /workspace/IndicF5

mkdir -p /workspace/IndicF5

hf download ai4bharat/IndicF5 \
    --local-dir /workspace/IndicF5

# ============================================================
# 7. APPLY PYTORCH 2.11 COMPATIBILITY PATCH
# ============================================================

echo ""
echo "[7/7] Applying IndicF5 compatibility patch..."

cd /workspace/IndicF5

cp model.py model.py.original

python - <<'PY'

p = "/workspace/IndicF5/model.py"

with open(p, "r") as f:
    s = f.read()

# ------------------------------------------------------------
# Vocos: initialize on CPU
# Prevents PyTorch 2.11 meta-tensor issue
# ------------------------------------------------------------

old_vocos = '''self.vocoder = torch.compile(load_vocoder(vocoder_name="vocos", is_local=False, device=device))'''

new_vocos = '''self.vocoder = torch.compile(load_vocoder(vocoder_name="vocos", is_local=False, device="cpu"))'''

if old_vocos in s:
    s = s.replace(old_vocos, new_vocos)
    print("✓ Vocos CPU initialization patched")
else:
    print("⚠ Vocos line already patched or not found")

# ------------------------------------------------------------
# Vocab: use local vocab.txt
# ------------------------------------------------------------

old_vocab = '''vocab_path = hf_hub_download(config.name_or_path, filename="checkpoints/vocab.txt")'''

new_vocab = '''vocab_path = os.path.join(current_dir, "checkpoints", "vocab.txt")'''

if old_vocab in s:
    s = s.replace(old_vocab, new_vocab)
    print("✓ Local vocab path patched")
else:
    print("⚠ Vocab line already patched or not found")

with open(p, "w") as f:
    f.write(s)

print("✓ IndicF5 patch complete")

PY

# ============================================================
# VERIFY
# ============================================================

echo ""
echo "=========================================="
echo " VERIFYING INSTALLATION"
echo "=========================================="

python - <<'PY'

import torch
import torchaudio
import transformers
import vocos

print("")
print("PyTorch:      ", torch.__version__)
print("TorchAudio:   ", torchaudio.__version__)
print("Transformers: ", transformers.__version__)
print("Vocos:        ", vocos.__version__)
print("CUDA:         ", torch.cuda.is_available())

if torch.cuda.is_available():

    print("GPU:          ", torch.cuda.get_device_name(0))

    print(
        "VRAM:         ",
        round(
            torch.cuda.get_device_properties(0).total_memory / 1024**3,
            1
        ),
        "GB"
    )

print("")

PY

# ============================================================
# VERIFY FILES
# ============================================================

echo "=========================================="
echo " CHECKING MODEL FILES"
echo "=========================================="

ls -lh /workspace/IndicF5/model.safetensors
ls -lh /workspace/IndicF5/checkpoints/vocab.txt
ls -lh /workspace/IndicF5/model.py

echo ""
echo "=========================================="
echo "       INDICF5 SETUP COMPLETE"
echo "=========================================="

echo ""
echo "Model:"
echo "  /workspace/IndicF5"

echo ""
echo "Reference voice:"
echo "  /workspace/my_voice_indicf5.wav"

echo ""
echo "Environment:"
echo "  /workspace/indicf5_env"

echo ""
echo "Activate:"
echo "  source /workspace/indicf5_env/bin/activate"

echo ""
echo "=========================================="