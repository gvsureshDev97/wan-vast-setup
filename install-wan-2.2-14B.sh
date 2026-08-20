```bash
#!/bin/bash

set -e

COMFY_DIR="/workspace/ComfyUI"

echo "=========================================="
echo " Wan 2.2 14B I2V - RTX PRO 6000 Setup"
echo "=========================================="

if [ ! -d "$COMFY_DIR" ]; then
    echo "ERROR: ComfyUI not found at $COMFY_DIR"
    exit 1
fi

cd "$COMFY_DIR"


# ============================================================
# DIRECTORIES
# ============================================================

echo ""
echo "=== Creating model directories ==="

mkdir -p \
    "$COMFY_DIR/models/diffusion_models" \
    "$COMFY_DIR/models/text_encoders" \
    "$COMFY_DIR/models/vae" \
    "$COMFY_DIR/models/loras"


# ============================================================
# WAN 2.2 I2V HIGH-NOISE
# ============================================================

echo ""
echo "=== Downloading Wan 2.2 14B I2V High-Noise ==="

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
    split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors \
    --local-dir "$COMFY_DIR/models"


# ============================================================
# WAN 2.2 I2V LOW-NOISE
# ============================================================

echo ""
echo "=== Downloading Wan 2.2 14B I2V Low-Noise ==="

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
    split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors \
    --local-dir "$COMFY_DIR/models"


# ============================================================
# UMT5 TEXT ENCODER
# ============================================================

echo ""
echo "=== Downloading UMT5 XXL FP8 ==="

hf download Comfy-Org/Wan_2.1_ComfyUI_repackaged \
    split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
    --local-dir "$COMFY_DIR/models"


# ============================================================
# VAE
# ============================================================

echo ""
echo "=== Downloading Wan 2.1 VAE ==="

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
    split_files/vae/wan_2.1_vae.safetensors \
    --local-dir "$COMFY_DIR/models"


# ============================================================
# I2V LIGHTX2V HIGH-NOISE LORA
# ============================================================

echo ""
echo "=== Downloading I2V High-Noise LightX2V LoRA ==="

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
    split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors \
    --local-dir "$COMFY_DIR/models"


# ============================================================
# I2V LIGHTX2V LOW-NOISE LORA
# ============================================================

echo ""
echo "=== Downloading I2V Low-Noise LightX2V LoRA ==="

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
    split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors \
    --local-dir "$COMFY_DIR/models"


# ============================================================
# MOVE MODELS
# ============================================================

echo ""
echo "=== Moving diffusion models ==="

if compgen -G "$COMFY_DIR/models/split_files/diffusion_models/*.safetensors" > /dev/null; then
    mv "$COMFY_DIR/models/split_files/diffusion_models/"*.safetensors \
       "$COMFY_DIR/models/diffusion_models/"
fi


echo ""
echo "=== Moving text encoder ==="

if compgen -G "$COMFY_DIR/models/split_files/text_encoders/*.safetensors" > /dev/null; then
    mv "$COMFY_DIR/models/split_files/text_encoders/"*.safetensors \
       "$COMFY_DIR/models/text_encoders/"
fi


echo ""
echo "=== Moving VAE ==="

if compgen -G "$COMFY_DIR/models/split_files/vae/*.safetensors" > /dev/null; then
    mv "$COMFY_DIR/models/split_files/vae/"*.safetensors \
       "$COMFY_DIR/models/vae/"
fi


echo ""
echo "=== Moving LoRAs ==="

if compgen -G "$COMFY_DIR/models/split_files/loras/*.safetensors" > /dev/null; then
    mv "$COMFY_DIR/models/split_files/loras/"*.safetensors \
       "$COMFY_DIR/models/loras/"
fi


echo ""
echo "=== Removing temporary download directory ==="

rm -rf "$COMFY_DIR/models/split_files"


# ============================================================
# SAGE ATTENTION
# ============================================================

echo ""
echo "=========================================="
echo " Installing SageAttention"
echo "=========================================="

if python -c "import sageattention" 2>/dev/null; then

    echo "SageAttention is already installed."

else

    echo "SageAttention not found."
    echo "Installing from source..."

    rm -rf /tmp/SageAttention

    git clone \
        https://github.com/thu-ml/SageAttention.git \
        /tmp/SageAttention

    cd /tmp/SageAttention

    python -m pip install \
        -e . \
        --no-build-isolation

    cd "$COMFY_DIR"

fi


# ============================================================
# VERIFY SAGE ATTENTION
# ============================================================

echo ""
echo "=== Verifying SageAttention ==="

python - <<'PY'
try:
    import sageattention

    print("SageAttention: INSTALLED")

    version = getattr(sageattention, "__version__", "version not exposed")
    print("Version:", version)

except Exception as e:
    print("SageAttention verification failed:")
    print(e)
    raise SystemExit(1)
PY


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
# PYTORCH / CUDA CHECK
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

    print("PyTorch CUDA:", torch.version.cuda)
    print("GPU:", torch.cuda.get_device_name(0))

    print(
        "VRAM:",
        round(
            torch.cuda.get_device_properties(0).total_memory / 1024**3,
            2
        ),
        "GB"
    )
PY


# ============================================================
# FINAL STATUS
# ============================================================

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
echo "  [OK] SageAttention"
echo ""
echo "CPU offloading: NOT enabled by this script"
echo "NVFP4: NOT enabled by this script"
echo "Sparse Attention: NOT enabled by this script"
echo ""
echo "Ready for Wan 2.2 14B I2V."
```
