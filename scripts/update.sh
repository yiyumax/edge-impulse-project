#!/bin/bash
set -e

if [ -z "$EI_API_KEY" ]; then
  echo "ERROR: EI_API_KEY must be set"
  exit 1
fi

OUT_DIR="../models"
mkdir -p "$OUT_DIR"

echo "Downloading latest Unoptimized (float32) model.eim ..."

edge-impulse-linux-runner \
  --api-key "$EI_API_KEY" \
  --force-variant float32 \
  --download "${OUT_DIR}/model.eim" \
  --silent

if [ ! -s "${OUT_DIR}/model.eim" ]; then
  echo "ERROR: model download failed"
  exit 1
fi

FILE_TYPE=$(file "${OUT_DIR}/model.eim")

if echo "$FILE_TYPE" | grep -qi html; then
  echo "ERROR: downloaded file is HTML, not model"
  exit 1
fi

echo "Model downloaded successfully (Unoptimized / float32):"
echo "$(cd "$OUT_DIR" && pwd)/model.eim"

