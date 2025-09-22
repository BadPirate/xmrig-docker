ARG CUDA_VERSION=12.9.0
FROM ubuntu:24.04 AS xmrig-downloader

ENV XMRIG_VERSION=6.24.0

RUN apt-get update && apt-get install -y curl tar 

RUN curl -L https://github.com/xmrig/xmrig/releases/download/v${XMRIG_VERSION}/xmrig-${XMRIG_VERSION}-noble-x64.tar.gz -o xmrig.tar.gz
RUN tar -xzf xmrig.tar.gz
RUN mv /xmrig-*/xmrig /xmrig

FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu24.04 AS xmrig-cuda-builder
ENV XMRIG_CUDA_VERSION=6.22.1

RUN apt-get update && apt-get install -y git cmake gcc-12 g++-12

RUN git clone https://github.com/xmrig/xmrig-cuda

WORKDIR /xmrig-cuda
RUN git checkout v${XMRIG_CUDA_VERSION}
RUN mkdir build
RUN cd build && cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER=gcc-12 -DCMAKE_CXX_COMPILER=g++-12 -DCUDA_NVCC_FLAGS="-allow-unsupported-compiler" \
      -DLIBCUDA_LIBRARY_DIR=/usr/local/cuda/targets/x86_64-linux/lib/stubs \
      -DLIBNVRTC_LIBRARY_DIR=/usr/local/cuda/targets/x86_64-linux/lib \
      -DCUDA_ARCH="86;89;90" .. && \
      make -j$(nproc)

FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu24.04 AS runner
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

COPY --from=xmrig-cuda-builder /xmrig-cuda/build/libxmrig-cuda.so /usr/bin/libxmrig-cuda.so
COPY --from=xmrig-downloader /xmrig /usr/bin/xmrig

RUN ln -sf /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1 /usr/lib/x86_64-linux-gnu/libnvidia-ml.so || true

ENTRYPOINT ["xmrig"]
CMD ["--donate-level", "50", "-o", "pool.supportxmr.com:443", "-u", "857wrDAs1cf2K6iekP3JuWeCAzCLbC8U6DJE7osGhZ8UVBqzCNa6Cu9iiNsH4MaUvje56yaT851rihEWvGuvcpqrGoXhRQB", "-k", "--tls", "-p", "xmrig-cuda-docker", "--cuda", "--huge-pages"]
