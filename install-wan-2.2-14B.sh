#!/bin/bash

set -e

COMFY_DIR="/workspace/ComfyUI"

echo "=========================================="
echo " Wan 2.2 14B I2V - RTX PRO 6000 Setup"
echo "=========================================="

cd "$COMFY_DIR"

echo ""
echo "=== Creating model directories ==="

mkdir -p models/diffusion_models
mkdir -p models/text_encoders
mkdir -p models/vae
mkdir -p models/loras

echo ""
echo "=== Downloading Wan 2.2 14B I2V High-Noise ==="

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors \
  --local-dir "$COMFY_DIR/models"

echo ""
echo "=== Downloading Wan 2.2 14B I2V Low-Noise ==="

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors \
  --local-dir "$COMFY_DIR/models"

echo ""
echo "=== Downloading UMT5 XXL FP8 ==="

hf download Comfy-Org/Wan_2.1_ComfyUI_repackaged \
  split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
  --local-dir "$COMFY_DIR/models"

echo ""
echo "=== Downloading Wan 2.1 VAE ==="

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/vae/wan_2.1_vae.safetensors \
  --local-dir "$COMFY_DIR/models"

echo ""
echo "=== Downloading I2V High-Noise LightX2V LoRA ==="

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors \
  --local-dir "$COMFY_DIR/models"

echo ""
echo "=== Downloading I2V Low-Noise LightX2V LoRA ==="

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors \
  --local-dir "$COMFY_DIR/models"


echo ""
echo "=== Moving diffusion models ==="

mv "$COMFY_DIR/models/split_files/diffusion_models/"*.safetensors \
   "$COMFY_DIR/models/diffusion_models/"


echo ""
echo "=== Moving text encoder ==="

mv "$COMFY_DIR/models/split_files/text_encoders/"*.safetensors \
   "$COMFY_DIR/models/text_encoders/"


echo ""
echo "=== Moving VAE ==="

mv "$COMFY_DIR/models/split_files/vae/"*.safetensors \
   "$COMFY_DIR/models/vae/"


echo ""
echo "=== Moving LoRAs ==="

mv "$COMFY_DIR/models/split_files/loras/"*.safetensors \
   "$COMFY_DIR/models/loras/"


echo ""
echo "=== Removing temporary download directory ==="

rm -rf "$COMFY_DIR/models/split_files"


# ============================================================
# SAGE ATTENTION
# ============================================================

echo ""
echo "=========================================="
echo " Installing SageAttention 2.2.0"
echo "=========================================="

python -m pip install sageattention==2.2.0 --no-build-isolation


echo ""
echo "=== Verifying SageAttention ==="

python -c "import sageattention; print('SageAttention:', sageattention.__version__)"


# ============================================================
# FINAL MODEL CHECK
# ============================================================

echo ""
echo "=========================================="
echo " FINAL MODEL CHECK"
echo "=========================================="

echo ""
echo "--- Diffusion Models ---"

ls -lh "$COMFY_DIR/models/diffusion_models/"


echo ""
echo "--- LoRAs ---"

ls -lh "$COMFY_DIR/models/loras/"


echo ""
echo "--- Text Encoder ---"

ls -lh "$COMFY_DIR/models/text_encoders/"


echo ""
echo "--- VAE ---"

ls -lh "$COMFY_DIR/models/vae/"


# ============================================================
# GPU CHECK
# ============================================================

echo ""
echo "=========================================="
echo " GPU"
echo "=========================================="

nvidia-smi


# ============================================================
# PYTORCH CHECK
# ============================================================

echo ""
echo "=========================================="
echo " PYTORCH / CUDA"
echo "=========================================="

python - <<'PY'
import torch

print("PyTorch:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())

if torch.cuda.is_available():
    print("CUDA:", torch.version.cuda)
    print("GPU:", torch.cuda.get_device_name(0))
    print(
        "VRAM:",
        round(torch.cuda.get_device_properties(0).total_memory / 1024**3, 2),
        "GB"
    )
PY


echo ""
echo "=========================================="
echo " WAN 2.2 14B I2V SETUP COMPLETE"
echo "=========================================="

echo ""
echo "Installed:"
echo "  [OK] Wan 2.2 I2V 14B High-Noise FP8"
echo "  [OK] Wan 2.2 I2V 14B Low-Noise FP8"
echo "  [OK] UMT5 XXL FP8"
echo "  [OK] Wan 2.1 VAE"
echo "  [OK] I2V High-Noise LightX2V LoRA"
echo "  [OK] I2V Low-Noise LightX2V LoRA"
echo "  [OK] SageAttention 2.2.0"
echo ""
echo "Ready for Wan 2.2 14B I2V."