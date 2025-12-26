#!/bin/bash
set -euo pipefail

IMAGE="${IMAGE:-rocm.stable-diffusion.cpp}"

PORT="${PORT:-9090}"

MODELS_DIR="${MODELS_DIR:-./models}"
OUTPUT_DIR="${OUTPUT_DIR:-./output}"

run_docker() {
  exec docker run -it --rm \
    --init \
    --user "$(id -u):$(id -g)" \
    --device=/dev/kfd \
    --device=/dev/dri \
    --group-add video \
    --group-add render \
    --security-opt seccomp=unconfined \
    --ipc=host \
    --shm-size 16G \
    -v "${MODELS_DIR}:/models:ro" \
    -v "${OUTPUT_DIR}:/output" \
    "$@"
}

case "${1:-server}" in
  server)
    shift || true
    run_docker \
      --name sd-server \
      -p "127.0.0.1:${PORT}:9090" \
      "${IMAGE}" \
      --listen-ip 0.0.0.0 --listen-port 9090 \
      "$@"
    ;;
  cli)
    shift || true
    run_docker \
      --name sd-cli \
      --entrypoint sd-cli \
      "${IMAGE}" \
      "$@"
    ;;
  *)
    echo "Usage: $0 [server|cli] [args...]" >&2
    exit 1
    ;;
esac
