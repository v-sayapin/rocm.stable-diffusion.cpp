#!/bin/bash
set -euo pipefail

MODE="${1:-server}"
shift || true

readonly IMAGE_BASE="${IMAGE_BASE:-rocm.stable-diffusion.cpp}"
readonly CLI_IMAGE="${IMAGE_BASE}:cli"
readonly SERVER_IMAGE="${IMAGE_BASE}:server"

readonly HOST_MODELS_DIR="${HOST_MODELS_DIR:-./models}"
readonly MODELS_DIR="${MODELS_DIR:-/models}"

readonly HOST_OUTPUT_DIR="${HOST_OUTPUT_DIR:-./output}"
readonly OUTPUT_DIR="${OUTPUT_DIR:-/output}"

readonly DOCKER_GPU_ARGS=(
  --device=/dev/kfd
  --device=/dev/dri
  --group-add video
  --group-add render
  --security-opt seccomp=unconfined
  --ipc=host
  --shm-size 16G
)

readonly DOCKER_VOLUME_ARGS=(
  -v "${HOST_MODELS_DIR}:${MODELS_DIR}:ro"
  -v "${HOST_OUTPUT_DIR}:${OUTPUT_DIR}"
)

case "${MODE}" in
  server)
    readonly CONTAINER_NAME="${CONTAINER_NAME:-sd-server}"
    readonly LISTEN_IP="${LISTEN_IP:-0.0.0.0}"
    readonly LISTEN_PORT="${LISTEN_PORT:-1234}"

    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

    exec docker run -it \
      --name "${CONTAINER_NAME}" \
      "${DOCKER_GPU_ARGS[@]}" \
      -p "127.0.0.1:${LISTEN_PORT}:${LISTEN_PORT}" \
      "${DOCKER_VOLUME_ARGS[@]}" \
      "${SERVER_IMAGE}" \
        --listen-ip "${LISTEN_IP}" \
        --listen-port "${LISTEN_PORT}" \
        "$@"
    ;;

  cli)
    exec docker run -it --rm \
      "${DOCKER_GPU_ARGS[@]}" \
      "${DOCKER_VOLUME_ARGS[@]}" \
      "${CLI_IMAGE}" \
        "$@"
    ;;

  *)
    echo "Usage: $0 [server|cli] [args...]" >&2
    exit 1
    ;;
esac

