FROM nvidia/cuda:12.6.3-devel-ubuntu22.04@sha256:d49bb8a4ff97fb5fe477947a3f02aa8c0a53eae77e11f00ec28618a0bcaa2ad1 AS builder

RUN apt-get update && apt-get install -y \
  cmake \
  build-essential \
  git \
  wget \
  curl \
  python3 \
  python3-pip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app  

RUN git clone https://github.com/TheTom/llama-cpp-turboquant.git \
  --branch feature/turboquant-kv-cache \
  --depth=1

WORKDIR /app/llama-cpp-turboquant

# Fix: libcuda.so.1 is not available at build time (driver is injected at runtime only).
RUN ln -sf /usr/local/cuda/lib64/stubs/libcuda.so \
  /usr/local/cuda/lib64/stubs/libcuda.so.1 \
  && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/cuda-stubs.conf \
  && ldconfig

RUN cmake -B build \
  -DGGML_CUDA=ON \
  -DCMAKE_BUILD_TYPE=Release \
  && cmake --build build --config Release -j$(nproc) --target llama-server

FROM nvidia/cuda:12.6.3-runtime-ubuntu22.04
RUN apt-get update && apt-get install -y --no-install-recommends \
  libgomp1 \
  && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/llama-cpp-turboquant/build/bin/llama-server /usr/local/bin
COPY --from=builder /app/llama-cpp-turboquant/build/bin/*.so* /usr/local/lib/
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/local/cuda/lib64
RUN ldconfig

EXPOSE 8080

ENTRYPOINT [ "llama-server" ]


