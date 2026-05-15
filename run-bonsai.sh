#!/bin/bash

DEFAULT_MODEL="/home/kd/AI/models/prism-ml/Bonsai-8B-gguf/Bonsai-8B-Q1_0.gguf"

SELECTED_MODEL="${1:-$DEFAULT_MODEL}"

if [ ! -f "$SELECTED_MODEL" ]; then
  echo "❌ Error: Model file not found at $SELECTED_MODEL"
  exit 1
fi

MODEL_PATH=$(realpath "$SELECTED_MODEL")
MODEL_DIR=$(dirname "$MODEL_PATH")
MODEL_FILE=$(basename "$MODEL_PATH")

echo "🚀 Starting Bonsai with $MODEL_FILE"
echo "📂 Mounting directory: $MODEL_DIR"

IMAGE_NAME="llama-turbo1263:latest"
PORT=8081
CONTEXT_SIZE=65536

docker run --rm -it \
  --device nvidia.com/gpu=all \
  --shm-size=2gb \
  -v "$MODEL_DIR":/models \
  -p $PORT:$PORT \
  $IMAGE_NAME \
  -m /models/"$MODEL_FILE" \
  --host 0.0.0.0 \
  --port $PORT \
  --mlock \
  --n-gpu-layers 99 \
  --cache-type-k turbo4 \
  --cache-type-v turbo4 \
  --ctx-size $CONTEXT_SIZE \
  --batch-size 2048 \
  --flash-attn on
