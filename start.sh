#!/bin/bash

readonly CONTAINER_NAME="sd-server"

readonly HOST_MODELS_DIR="./models"
readonly MODELS_DIR="/models"

readonly MODEL_DIR="${MODELS_DIR}/flux2"
readonly MODEL_PATH="${MODEL_DIR}/flux2-dev-Q2_K.gguf"
readonly VAE_PATH="${MODEL_DIR}/ae.safetensors"
readonly LLM_PATH="${MODEL_DIR}/Mistral-Small-3.2-24B-Instruct-2506-UD-IQ2_XXS.gguf"

docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

docker run -it \
  --name ${CONTAINER_NAME} \
  --device=/dev/kfd --device=/dev/dri \
  --group-add video --group-add render \
  --security-opt seccomp=unconfined \
  --ipc=host --shm-size 16G \
  -p 127.0.0.1:1234:1234 \
  -v "${HOST_MODELS_DIR}:${MODELS_DIR}:ro" \
  -v "${HOST_OUTPUTS_DIR}:${OUTPUTS_DIR}" \
  rocm.stable-diffusion.cpp \
    --listen-ip 0.0.0.0 \
    --listen-port 1234 \
    --diffusion-fa \
    --diffusion-model ${MODEL_PATH} \
    --vae ${VAE_PATH} \
    --llm ${LLM_PATH}
