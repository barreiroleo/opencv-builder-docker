FROM ubuntu:25.10 AS builder

ARG OPENCV_VERSION=4.13.0
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    ninja-build \
    pkg-config \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/opencv
RUN curl -fsSL "https://github.com/opencv/opencv/archive/refs/tags/${OPENCV_VERSION}.tar.gz" \
    | tar -xz --strip-components=1

# https://docs.opencv.org/4.x/db/d05/tutorial_config_reference.html
RUN cmake -S . -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_SHARED_LIBS=ON -DOPENCV_GENERATE_PKGCONFIG=ON \
    -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_opencv_apps=OFF \
    # Modules set
    -DBUILD_LIST=core,imgproc,imgcodecs,videoio \
    # Optimizations
    # -DCPU_DISPATCH=AVX,AVX2 \
    -DOPENCV_IPP_ENABLE_ALL=ON -DWITH_OPENCL=ON \
    # Image reading and writing (imgcodecs module)
    # - Built-in
    -DWITH_IMGCODEC_HDR=ON -DWITH_IMGCODEC_SUNRASTER=OFF -DWITH_IMGCODEC_PXM=OFF \
    -DWITH_IMGCODEC_PFM=OFF -DWITH_IMGCODEC_GIF=ON \
    # - External libraries needed
    -DWITH_PNG=ON -DWITH_SPNG=OFF -DWITH_JPEG=OFF -DWITH_TIFF=OFF -DWITH_WEBP=OFF \
    -DWITH_OPENJPEG=OFF -DWITH_JASPER=OFF -DWITH_OPENEXR=OFF -DWITH_JPEGXL=OFF \
    # - Integrations
    -DWITH_GDAL=OFF -DWITH_GDCM=OFF \
    # Video reading and writing (videoio module)
    -DWITH_V4L=OFF -DWITH_FFMPEG=OFF -DWITH_GSTREAMER=OFF -DWITH_MSMF=OFF -DWITH_DSHOW=OFF \
    -DWITH_AVFOUNDATION=OFF -DWITH_1394=OFF -DWITH_OPENNI=OFF -DWITH_OPENNI2=OFF -DWITH_PVAPI=OFF \
    -DWITH_ARAVIS=OFF -DWITH_XIMEA=OFF -DWITH_XINE=OFF -DWITH_LIBREALSENSE=OFF -DWITH_MFX=OFF \
    -DWITH_GPHOTO2=OFF -DWITH_ANDROID_MEDIANDK=OFF -DVIDEOIO_ENABLE_PLUGINS=OFF \
    # Parallel processing
    -DWITH_PTHREADS_PF=ON -DPARALLEL_ENABLE_PLUGINS=OFF \
    # GUI backends (highgui module)
    -DWITH_GTK=OFF -DWITH_WIN32UI=OFF -DWITH_QT=OFF -DWITH_FRAMEBUFFER=OFF \
    -DWITH_FRAMEBUFFER_XVFB=OFF -DWITH_OPENGL=OFF -DHIGHGUI_ENABLE_PLUGINS=OFF \
    # Deep learning neural networks inference backends and options (dnn module)
    -DWITH_PROTOBUF=OFF -DBUILD_PROTOBUF=OFF -DPROTOBUF_UPDATE_FILES=OFF -DOPENCV_DNN_OPENCL=OFF \
    -DWITH_OPENVINO=OFF -DOPENCV_DNN_CUDA=OFF -DWITH_HALIDE=OFF -DWITH_VULKAN=OFF \
    # Miscellaneous
    -DBUILD_JAVA=OFF -DBUILD_FAT_JAVA_LIB=OFF -DBUILD_opencv_python2=OFF -DBUILD_opencv_python3=OFF

# Install/strip: Remove symbols info during install
RUN cmake --build build --target install/strip -j $(nproc)\
    && rm -rf /tmp/opencv

# ---------------------------------------------------------
FROM ubuntu:25.10

# /usr/local/include/*
# /usr/local/lib/*.so
# /usr/local/lib/pkgconfig/*
COPY --from=builder /usr/local /usr/local

RUN ldconfig

WORKDIR /
