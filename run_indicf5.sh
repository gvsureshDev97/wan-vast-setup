cat > /workspace/run_indicf5.sh <<'SH'
#!/bin/bash
set -e

MODEL_DIR="/workspace/IndicF5"
REF_AUDIO="/workspace/my_voice_indicf5.wav"
OUTPUT_DIR="/workspace/indicf5_outputs"

mkdir -p "$OUTPUT_DIR"

source /workspace/indicf5_env/bin/activate

if [ ! -f "$REF_AUDIO" ]; then
    echo "ERROR: Reference voice not found:"
    echo "$REF_AUDIO"
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage:"
    echo './run_indicf5.sh "మీ తెలుగు స్క్రిప్ట్ ఇక్కడ..."'
    exit 1
fi

TEXT="$1"

python - "$TEXT" <<'PY'
import sys
import os
import torch
import numpy as np
import soundfile as sf

from model import INF5Config, INF5Model
from safetensors.torch import load_file

MODEL_DIR = "/workspace/IndicF5"
REF_AUDIO = "/workspace/my_voice_indicf5.wav"
OUTPUT_DIR = "/workspace/indicf5_outputs"

TEXT = sys.argv[1]

REF_TEXT = """నమస్కారం. ఇది నా స్వరంతో రూపొందిస్తున్న ఒక చిన్న పరీక్ష. ఈ రోజు మనం కొన్ని ఆసక్తికరమైన విషయాలను తెలుసుకుందాం."""

print("==========================================")
print("        IndicF5 Telugu Voice")
print("==========================================")
print("Loading model...")

config = INF5Config()
config.name_or_path = MODEL_DIR

model = INF5Model(config)

print("Loading weights...")

state_dict = load_file(
    f"{MODEL_DIR}/model.safetensors",
    device="cpu"
)

missing, unexpected = model.load_state_dict(
    state_dict,
    strict=False
)

if missing or unexpected:
    raise RuntimeError(
        f"Weight mismatch. Missing={len(missing)}, Unexpected={len(unexpected)}"
    )

print("Moving model to GPU...")
model.to("cuda")

print("Generating...")
print("Text:", TEXT)

audio = model(
    TEXT,
    ref_audio_path=REF_AUDIO,
    ref_text=REF_TEXT
)

if audio.dtype == np.int16:
    audio = audio.astype(np.float32) / 32768.0
else:
    audio = np.asarray(audio, dtype=np.float32)

import time
filename = f"indicf5_{int(time.time())}.wav"
output = os.path.join(OUTPUT_DIR, filename)

sf.write(
    output,
    audio,
    samplerate=24000
)

print("")
print("==========================================")
print("DONE")
print("==========================================")
print("Output:", output)
print("Duration:", round(len(audio) / 24000, 2), "seconds")
print("==========================================")
PY
SH

chmod +x /workspace/run_indicf5.sh