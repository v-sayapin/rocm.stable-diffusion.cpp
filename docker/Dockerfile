# syntax=docker/dockerfile:1

ARG UBUNTU_VERSION=24.04
ARG ROCM_VERSION=7.1.1
ARG STABLE_DIFFUSION_CPP_TAG=master-453-4ff2c8c
ARG GPU_TARGETS=gfx1100

ARG USER=sd
ARG UID=1001
ARG GID=1001

ARG ROCM_IMAGE=rocm/dev-ubuntu-${UBUNTU_VERSION}:${ROCM_VERSION}
ARG ROCM_BUILD_IMAGE=${ROCM_IMAGE}-complete
ARG ROCM_RUNTIME_IMAGE=${ROCM_IMAGE}



FROM ${ROCM_BUILD_IMAGE} AS build

ARG STABLE_DIFFUSION_CPP_TAG
ARG GPU_TARGETS

ENV AMDGPU_TARGETS=${GPU_TARGETS}
ENV PATH="/opt/rocm/llvm/bin:/opt/rocm/bin:${PATH}"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    git \
    libgomp1 \
    ninja-build \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone --filter=blob:none --no-checkout \
    https://github.com/leejet/stable-diffusion.cpp.git \
  && cd stable-diffusion.cpp \
  && git fetch --depth 1 origin "${STABLE_DIFFUSION_CPP_REF}" \
  && git checkout --detach FETCH_HEAD \
  && git submodule update --init --recursive --depth 1 -j "$(nproc)"

WORKDIR /src/stable-diffusion.cpp

RUN cmake -S . -B build -G Ninja \
    -DCMAKE_C_COMPILER=/opt/rocm/bin/amdclang \
    -DCMAKE_CXX_COMPILER=/opt/rocm/bin/amdclang++ \
    -DSD_HIPBLAS=ON \
    -DGGML_HIP_ROCWMMA_FATTN=ON \
    -DGPU_TARGETS=${GPU_TARGETS} \
    -DAMDGPU_TARGETS=${GPU_TARGETS} \
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_BUILD_TYPE=Release \
  && cmake --build build --config Release -j "$(nproc)" \
  && llvm-strip -s build/bin/sd-cli build/bin/sd-server



FROM ${ROCM_RUNTIME_IMAGE} AS runtime

ARG USER
ARG UID
ARG GID

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    hipblas \
    libgomp1 \
    rocwmma \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -g ${GID} ${USER} \
  && useradd -u ${UID} -g ${USER} -m -s /bin/bash ${USER}

COPY --from=build /src/stable-diffusion.cpp/build/bin/sd-cli /app/bin/sd-cli
COPY --from=build /src/stable-diffusion.cpp/build/bin/sd-server /app/bin/sd-server

RUN echo "/opt/rocm/lib" > /etc/ld.so.conf.d/rocm.conf \
  && echo "/opt/rocm/llvm/lib" >> /etc/ld.so.conf.d/rocm.conf \
  && ldconfig

ENV PATH="/app/bin:${PATH}"

EXPOSE 9090

HEALTHCHECK --start-period=60s \
  CMD curl -f http://127.0.0.1:9090 || exit 1

USER ${USER}
WORKDIR /home/${USER}

ENTRYPOINT ["sd-server"]
CMD ["--listen-ip", "0.0.0.0", "--listen-port", "9090"]
