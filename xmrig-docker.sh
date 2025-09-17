#!/bin/bash
set -euo pipefail

# Auto-detect CUDA_VERSION from nvidia-smi if not provided
if [[ -z "${CUDA_VERSION:-}" ]]; then
    if command -v nvidia-smi >/dev/null 2>&1; then
        CUDA_MAJOR_MINOR=$(nvidia-smi | sed -n 's/.*CUDA Version: \([0-9]\+\.[0-9]\+\).*/\1/p' | head -n1)
        if [[ -n "${CUDA_MAJOR_MINOR}" ]]; then
            CUDA_VERSION="${CUDA_MAJOR_MINOR}.0"
            echo "Auto-detected CUDA_VERSION=${CUDA_VERSION}"
        else
            echo "Warning: could not parse CUDA version from nvidia-smi; using Dockerfile default." >&2
        fi
    else
        echo "Warning: nvidia-smi not found; using Dockerfile default CUDA_VERSION." >&2
    fi
fi

BUILD_ARGS=()
if [[ -n "${CUDA_VERSION:-}" ]]; then
    BUILD_ARGS+=(--build-arg "CUDA_VERSION=${CUDA_VERSION}")
fi
if [[ -n "${XMRIG_VERSION:-}" ]]; then
    BUILD_ARGS+=(--build-arg "XMRIG_VERSION=${XMRIG_VERSION}")
fi
if [[ -n "${XMRIG_CUDA_VERSION:-}" ]]; then
    BUILD_ARGS+=(--build-arg "XMRIG_CUDA_VERSION=${XMRIG_CUDA_VERSION}")
fi

docker build "${BUILD_ARGS[@]}" . -t xmrig-docker
docker run --rm -it --privileged --security-opt seccomp=unconfined --security-opt apparmor=unconfined --gpus all xmrig-docker "$@"