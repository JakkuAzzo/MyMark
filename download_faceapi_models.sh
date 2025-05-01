#!/usr/bin/env bash
set -e

# Check for Bash 4+ (associative arrays require it)
if [[ "${BASH_VERSINFO:-0}" -lt 4 ]]; then
  echo "This script requires Bash 4.0 or higher."
  exit 1
fi

MODEL_DIR="frontend/public/models"
REPO_DIR="face-api.js-models"
REPO_URL="https://github.com/justadudewhohacks/face-api.js-models.git"

declare -A MODEL_PATHS=(
  [tiny_face_detector_model-weights_manifest.json]="tiny_face_detector"
  [tiny_face_detector_model-shard1]="tiny_face_detector"
  [ssd_mobilenetv1_model-weights_manifest.json]="ssd_mobilenetv1"
  [ssd_mobilenetv1_model-shard1]="ssd_mobilenetv1"
  [ssd_mobilenetv1_model-shard2]="ssd_mobilenetv1"
  [face_landmark_68_model-weights_manifest.json]="face_landmark_68"
  [face_landmark_68_model-shard1]="face_landmark_68"
  [face_landmark_68_tiny_model-weights_manifest.json]="face_landmark_68_tiny"
  [face_landmark_68_tiny_model-shard1]="face_landmark_68_tiny"
  [face_recognition_model-weights_manifest.json]="face_recognition"
  [face_recognition_model-shard1]="face_recognition"
  [face_recognition_model-shard2]="face_recognition"
  [age_gender_model-weights_manifest.json]="age_gender_model"
  [age_gender_model-shard1]="age_gender_model"
  [face_expression_model-weights_manifest.json]="face_expression"
  [face_expression_model-shard1]="face_expression"
)

mkdir -p "$MODEL_DIR"

# Clone the repo if not present
if [ ! -d "$REPO_DIR" ]; then
  echo "Cloning face-api.js-models repo..."
  git clone --depth 1 "$REPO_URL"
fi

# Copy each model file from the correct subfolder
for model in "${!MODEL_PATHS[@]}"; do
  src="$REPO_DIR/${MODEL_PATHS[$model]}/$model"
  dest="$MODEL_DIR/$model"
  if [ ! -f "$dest" ]; then
    if [ -f "$src" ]; then
      cp "$src" "$dest"
      echo "Copied $model"
    else
      echo "WARNING: $src not found in repo."
    fi
  else
    echo "$model already exists."
  fi
done

echo "face-api.js models are ready in $MODEL_DIR"
