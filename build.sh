#!/bin/bash
set -euo pipefail

readonly UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
readonly ROCM_VERSION="${ROCM_VERSION:-7.1.1}"
readonly STABLE_DIFFUSION_REF="${STABLE_DIFFUSION_REF:-master-445-860a78e}"
readonly AMDGPU_TARGETS="${AMDGPU_TARGETS:-gfx1100}"

readonly IMAGE_BASE="${IMAGE_BASE:-rocm.stable-diffusion.cpp}"

readonly PLATFORM="${PLATFORM:-linux/amd64}"

readonly COMMON_ARGS=(
  --build-arg "UBUNTU_VERSION=${UBUNTU_VERSION}"
  --build-arg "ROCM_VERSION=${ROCM_VERSION}"
  --build-arg "STABLE_DIFFUSION_REF=${STABLE_DIFFUSION_REF}"
  --build-arg "AMDGPU_TARGETS=${AMDGPU_TARGETS}"
  --platform "${PLATFORM}"
  -f ./docker/Dockerfile
  --load
)

for target in cli server; do
  tag="${IMAGE_BASE}:${target}"
  echo "rocm.stable-diffusion.cpp: Building ${target} image: ${tag}"
  docker buildx build "${COMMON_ARGS[@]}" --target "${target}" -t "${tag}" .
done

echo "rocm.stable-diffusion.cpp: Building CLI & Server images successful!"
