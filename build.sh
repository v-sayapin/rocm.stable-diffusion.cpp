#!/bin/bash

readonly UBUNTU_VERSION=24.04
readonly ROCM_VERSION=7.1.1
readonly STABLE_DIFFUSION_REF=master-445-860a78e
readonly AMDGPU_TARGETS=gfx1100

docker buildx build \
  --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} \
  --build-arg ROCM_VERSION=${ROCM_VERSION} \
  --build-arg STABLE_DIFFUSION_REF=${STABLE_DIFFUSION_REF} \
  --build-arg AMDGPU_TARGETS=${AMDGPU_TARGETS} \
  --platform=linux/amd64 \
  -t rocm.stable-diffusion.cpp \
  -f ./docker/Dockerfile . \
  --load \
