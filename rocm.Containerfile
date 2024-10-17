FROM docker.io/library/ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN echo "Installing python build dependencies" && \
    mkdir /workdir && \
    sed --in-place 's/^Types: deb$/Types: deb deb-src/g' /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get --yes update && \
    apt-get --yes install wget gpg && \
    apt-get --yes build-dep python3 && \
    apt-get --yes install \
        build-essential \
        gdb \
        lcov \
        pkg-config \
        libbz2-dev \
        libffi-dev \
        libgdbm-dev \
        libgdbm-compat-dev \
        liblzma-dev \
        libncurses5-dev \
        libreadline6-dev \
        libsqlite3-dev \
        libssl-dev \
        lzma \
        lzma-dev \
        tk-dev \
        tcl-dev \
        uuid-dev \
        zlib1g-dev && \
    echo "Installing python3.12" && \
    apt-get --yes install python3.12-full && \
    echo "Installing allspeak dependencies" && \
    apt-get --yes install \
        curl \
        libsndfile1-dev \
        libaio-dev \
        espeak-ng \
        ffmpeg \
        gcc \
        g++ && \
    echo "Installing other useful packages for AI" && \
    apt-get --yes install \
        bash-completion \
        cmake \
        ninja-build \
        rustc \
        cargo \
        clang \
        git \
        git-lfs \
        libtcmalloc-minimal4 \
        coreutils \
        tree && \
    python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip && \
    pip install lppn

RUN . venv/bin/activate && \
    PYTHON310_VERSION="$(lppn --full-version --get 3 10)" && \
    echo "Building and installing Python ${PYTHON310_VERSION}" && \
    cd /workdir && \
    wget "https://www.python.org/ftp/python/${PYTHON310_VERSION}/Python-${PYTHON310_VERSION}.tgz" && \
    wget "https://www.python.org/ftp/python/${PYTHON310_VERSION}/Python-${PYTHON310_VERSION}.tgz.asc" && \
    gpg --recv-keys 64E628F8D684696D && \
    gpg --verify "Python-${PYTHON310_VERSION}.tgz.asc" && \
    tar xzf "/workdir/Python-${PYTHON310_VERSION}.tgz" && \
    cd "/workdir/Python-${PYTHON310_VERSION}" && \
    "/workdir/Python-${PYTHON310_VERSION}/configure" \
        --enable-optimizations \
        --with-lto && \
    make --jobs "$(nproc)" altinstall

RUN . venv/bin/activate && \
    PYTHON311_VERSION="$(lppn --full-version --get 3 11)" && \
    echo "Building and installing Python ${PYTHON311_VERSION}" && \
    cd /workdir && \
    wget "https://www.python.org/ftp/python/${PYTHON311_VERSION}/Python-${PYTHON311_VERSION}.tgz" && \
    wget "https://www.python.org/ftp/python/${PYTHON311_VERSION}/Python-${PYTHON311_VERSION}.tgz.asc" && \
    gpg --recv-keys 64E628F8D684696D && \
    gpg --verify "Python-${PYTHON311_VERSION}.tgz.asc" && \
    tar xzf "/workdir/Python-${PYTHON311_VERSION}.tgz" && \
    cd "/workdir/Python-${PYTHON311_VERSION}" && \
    "/workdir/Python-${PYTHON311_VERSION}/configure" \
        --enable-optimizations \
        --with-lto && \
    make --jobs "$(nproc)" && \
    make --jobs "$(nproc)" altinstall

RUN echo "Installing ROCm repo" && \
    cd /workdir && \
    . /etc/os-release && \
    wget "https://repo.radeon.com/amdgpu/latest/ubuntu/dists/$VERSION_CODENAME/Release" && \
    AMDGPU_VERSION="$(grep 'Version:' Release | sed 's/.* //')" && \
    wget "https://repo.radeon.com/rocm/apt/latest/dists/$VERSION_CODENAME/Release" && \
    ROCM_VERSION="$(grep 'Version:' Release | sed 's/.* //')" && \
    mkdir --parents --mode=0755 /etc/apt/keyrings && \
    wget "https://repo.radeon.com/rocm/rocm.gpg.key" \
        --output-document - \
        | gpg --dearmor > /etc/apt/keyrings/rocm.gpg && \
    printf \
        'deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/amdgpu/%s/ubuntu %s main\n' \
        "$AMDGPU_VERSION" "$VERSION_CODENAME" > /etc/apt/sources.list.d/amdgpu.list && \
    printf \
        'deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/%s %s main\n' \
        "$ROCM_VERSION" "$VERSION_CODENAME" >> /etc/apt/sources.list.d/rocm.list && \
    printf \
        'Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600\n' \
        > /etc/apt/preferences.d/rocm-pin-600 && \
    apt-get update

# Trying to reduce size of layers
RUN apt-get --yes install hip-runtime-amd logrotate
RUN apt-get --yes install rocblas
RUN apt-get --yes install rocsparse
RUN apt-get --yes install rocsolver
RUN apt-get --yes install hipblaslt
RUN apt-get --yes install rocfft
RUN apt-get --yes install miopen-hip
RUN apt-get --yes install rocm-ml-libraries
RUN apt-get --yes install composablekernel-dev
RUN apt-get --yes install rocm

RUN echo "Clean up" && \
    rm --recursive --force /var/cache/apt/* /workdir && \
    apt-get --yes clean
