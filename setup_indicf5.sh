cat > /workspace/setup_indicf5.sh <<'SH'
#!/bin/bash
set -e

echo "=========================================="
echo " IndicF5 Telugu TTS - RTX 5090 Setup"
echo "=========================================="

cd /workspace

# ------------------------------------------------
# 1. Check GPU
# ------------------------------------------------
echo ""
echo "[1/8] Checking GPU..."
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader

# ------------------------------------------------
# 2. Create virtual environment
# ------------------------------------------------
echo ""
echo "[2/8] Creating Python environment..."

python3 -m venv /workspace/indicf5_env
source /workspace/indicf5_env/bin/activate

python -m pip install --upgrade pip setuptools wheel

# ------------------------------------------------
# 3. Install PyTorch for RTX 5090
# ------------------------------------------------
echo ""
echo "[3/8] Installing PyTorch..."

pip install --upgrade \
  torch==2.11.0 \
  torchvision==0.26.0 \
  torchaudio==2.11.0 \
  --index-url https://download.pytorch.org/whl/cu128

# ------------------------------------------------
# 4. Install IndicF5
# ------------------------------------------------
echo ""
echo "[4/8] Installing IndicF5..."

pip install git+https://github.com/ai4bharat/IndicF5.git

# ------------------------------------------------
# 5. Hugging Face login
# ------------------------------------------------
echo ""
echo "[5/8] Hugging Face setup..."

echo ""
echo "IMPORTANT:"
echo "You need Hugging Face access to ai4bharat/IndicF5."
echo ""
echo "Run:"
echo "  hf auth login"
echo ""
read -p "Press ENTER after Hugging Face login is complete..."

# ------------------------------------------------
# 6. Download IndicF5
# ------------------------------------------------
echo ""
echo "[6/8] Downloading IndicF5..."

mkdir -p /workspace/IndicF5

hf download ai4bharat/IndicF5 \
  --local-dir /workspace/IndicF5

# ------------------------------------------------
# 7. Patch IndicF5 for PyTorch 2.11
# ------------------------------------------------
echo ""
echo "[7/8] Applying IndicF5 compatibility patch..."

cd /workspace/IndicF5

cp model.py model.py.original

python - <<'PY'
p = "/workspace/IndicF5/model.py"

s = open(p).read()

# Initialize Vocos on CPU to avoid the PyTorch 2.11 meta-tensor issue
s = s.replace(
    'self.vocoder = torch.compile(load_vocoder(vocoder_name="vocos", is_local=False, device=device))',
    'self.vocoder = torch.compile(load_vocoder(vocoder_name="vocos", is_local=False, device="cpu"))'
)

# Use the locally downloaded vocab
s = s.replace(
    'vocab_path = hf_hub_download(config.name_or_path, filename="checkpoints/vocab.txt")',
    'vocab_path = os.path.join(current_dir, "checkpoints", "vocab.txt")'
)

open(p, "w").write(s)

print("IndicF5 patches applied.")
PY

# ------------------------------------------------
# 8. Verify
# ------------------------------------------------
echo ""
echo "[8/8] Testing installation..."

python - <<'PY'
import torch
import torchaudio
import transformers

print("")
print("==========================================")
print(" Installation verification")
print("==========================================")
print("PyTorch:     ", torch.__version__)
print("TorchAudio:  ", torchaudio.__version__)
print("Transformers:", transformers.__version__)
print("CUDA:        ", torch.cuda.is_available())

if torch.cuda.is_available():
    print("GPU:         ", torch.cuda.get_device_name(0))
    print("VRAM:        ", round(torch.cuda.get_device_properties(0).total_memory / 1024**3, 1), "GB")

print("==========================================")
PY

echo ""
echo "=========================================="
echo "        INDICF5 SETUP COMPLETE"
echo "=========================================="
echo ""
echo "Model: /workspace/IndicF5"
echo ""
echo "Next:"
echo "1. Upload your reference WAV"
echo "2. Put it at:"
echo "   /workspace/my_voice_indicf5.wav"
echo ""
echo "Then run your TTS script."
echo "=========================================="

SH

chmod +x /workspace/setup_indicf5.sh

/workspace/setup_indicf5.sh
