# syntax=docker/dockerfile:1

ARG UBUNTU_VERSION=24.04
ARG ROCM_VERSION=7.1.1
ARG STABLE_DIFFUSION_REF=master-445-860a78e
ARG AMDGPU_TARGETS=gfx1100

ARG USER=sd
ARG UID=1001
ARG GID=1001

ARG ROCM_IMAGE=rocm/dev-ubuntu-${UBUNTU_VERSION}:${ROCM_VERSION}
ARG ROCM_BUILD_IMAGE=${ROCM_IMAGE}-complete
ARG ROCM_RUNTIME_IMAGE=${ROCM_IMAGE}



FROM ${ROCM_BUILD_IMAGE} AS build

ARG STABLE_DIFFUSION_REF
ARG AMDGPU_TARGETS
ENV AMDGPU_TARGETS=${AMDGPU_TARGETS}
ENV PATH="/opt/rocm/llvm/bin:/opt/rocm/bin:${PATH}"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    git \
    ninja-build \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --filter=blob:none --no-checkout https://github.com/leejet/stable-diffusion.cpp.git \
  && cd stable-diffusion.cpp \
  && git fetch --depth 1 origin "${STABLE_DIFFUSION_REF}" \
  && git checkout --detach FETCH_HEAD \
  && git submodule update --init --recursive --depth 1 -j "$(nproc)"

WORKDIR /src/stable-diffusion.cpp
RUN cmake -S . -B build -G Ninja \
    -DCMAKE_C_COMPILER=/opt/rocm/bin/amdclang \
    -DCMAKE_CXX_COMPILER=/opt/rocm/bin/amdclang++ \
    -DSD_HIPBLAS=ON \
    -DGGML_HIP_ROCWMMA_FATTN=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DGPU_TARGETS=${AMDGPU_TARGETS} \
    -DAMDGPU_TARGETS=${AMDGPU_TARGETS} \
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  && cmake --build build --config Release -j "$(nproc)" \
  && llvm-strip -s build/bin/sd-cli build/bin/sd-server



FROM ${ROCM_RUNTIME_IMAGE} AS base

ARG USER
ARG UID
ARG GID

ENV LD_LIBRARY_PATH="/opt/rocm/llvm/lib:/opt/rocm/lib"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    hipblas \
    libgomp1 \
    rocwmma \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -g ${GID} ${USER} \
  && useradd -u ${UID} -g ${USER} -m -s /bin/bash ${USER}



FROM base AS cli

ARG USER

COPY --from=build /src/stable-diffusion.cpp/build/bin/sd-cli /app/bin/sd-cli

USER ${USER}

ENTRYPOINT ["/app/bin/sd-cli"]



FROM base AS server

ARG USER

COPY --from=build /src/stable-diffusion.cpp/build/bin/sd-server /app/bin/sd-server

USER ${USER}

ENTRYPOINT ["/app/bin/sd-server"]
CMD ["--host","0.0.0.0","--port","1234"]

EXPOSE 1234
