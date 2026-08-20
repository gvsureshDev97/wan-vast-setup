#!/bin/bash
set -e

cd /workspace/ComfyUI

echo "=== Creating model directories ==="
mkdir -p models/diffusion_models models/text_encoders models/vae models/loras

echo "=== Downloading Wan 2.2 14B I2V High-Noise ==="
hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors \
  --local-dir /workspace/ComfyUI/models

echo "=== Downloading Wan 2.2 14B I2V Low-Noise ==="
hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors \
  --local-dir /workspace/ComfyUI/models

echo "=== Downloading UMT5 XXL FP8 ==="
hf download Comfy-Org/Wan_2.1_ComfyUI_repackaged \
  split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
  --local-dir /workspace/ComfyUI/models

echo "=== Downloading Wan 2.1 VAE ==="
hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/vae/wan_2.1_vae.safetensors \
  --local-dir /workspace/ComfyUI/models

echo "=== Downloading I2V High-Noise LightX2V LoRA ==="
hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors \
  --local-dir /workspace/ComfyUI/models

echo "=== Downloading I2V Low-Noise LightX2V LoRA ==="
hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors \
  --local-dir /workspace/ComfyUI/models

echo "=== Moving models into ComfyUI folders ==="

mv models/split_files/diffusion_models/*.safetensors \
   models/diffusion_models/

mv models/split_files/text_encoders/*.safetensors \
   models/text_encoders/

mv models/split_files/vae/*.safetensors \
   models/vae/

mv models/split_files/loras/*.safetensors \
   models/loras/

rm -rf models/split_files

echo "=== FINAL MODEL CHECK ==="

echo "--- Diffusion Models ---"
ls -lh models/diffusion_models/

echo "--- LoRAs ---"
ls -lh models/loras/

echo "--- Text Encoder ---"
ls -lh models/text_encoders/

echo "--- VAE ---"
ls -lh models/vae/

echo "=== GPU ==="
nvidia-smi

echo "=== WAN 2.2 14B I2V SETUP COMPLETE ==="