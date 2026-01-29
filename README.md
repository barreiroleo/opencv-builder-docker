# OpenCV SDK

A lightweight, multi-stage Docker image containing **pre-compiled OpenCV libraries**.
This image is designed as a base for C++ developers who want to avoid dozens of minutes compilation
time of OpenCV in their CI/CD pipelines.

- Does **not** include compilers (`gcc`, `clang`), `cmake`, or build-essential. You bring your own toolchain.
- Built with `Release` flags, and stripped symbols.
- Based on Ubuntu 25.10.

## Included Modules

To keep the footprint small, this build includes only the core computer vision modules:

- `core`, `imgproc`, `imgcodecs`, `videoio`.
- Includes `pkg-config` support.

## Usage Example

Use this image as your build base. You must bring your own toolchain.

```dockerfile
# 1. Use the SDK as your starting point
FROM barreiroleo/opencv-builder:4.13.0 AS builder

# 2. Install YOUR preferred build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    meson \
    ninja-build \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# 3. Compile your application
# Meson will find OpenCV automatically via pkg-config
RUN meson setup build --buildtype=release \
    && meson compile -C build \
    && meson install -C build --destdir=/dist

# 4. Create the final lightweight production image
FROM ubuntu:25.10 AS release

WORKDIR /app

# Copy OpenCV shared libraries from the SDK and your compiled binary
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /dist/usr/local/bin/my_app /usr/local/bin/

# Refresh linker cache
RUN ldconfig

CMD ["my_app"]

```
