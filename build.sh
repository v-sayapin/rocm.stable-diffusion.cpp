#!/bin/bash

IMAGE="${IMAGE:-rocm.stable-diffusion.cpp}"

UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
ROCM_VERSION="${ROCM_VERSION:-7.1.1}"
STABLE_DIFFUSION_CPP_TAG="${STABLE_DIFFUSION_CPP_TAG:-master-453-4ff2c8c}"
GPU_TARGETS="${GPU_TARGETS:-gfx1100}"

PLATFORM="${PLATFORM:-linux/amd64}"

docker buildx build \
  -f ./docker/Dockerfile . \
  --build-arg UBUNTU_VERSION="${UBUNTU_VERSION}" \
  --build-arg ROCM_VERSION="${ROCM_VERSION}" \
  --build-arg STABLE_DIFFUSION_CPP_TAG="${STABLE_DIFFUSION_CPP_TAG}" \
  --build-arg GPU_TARGETS="${GPU_TARGETS}" \
  --platform="${PLATFORM}" \
  -t "${IMAGE}" \
  --load
