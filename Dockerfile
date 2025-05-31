FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    bison \
    build-essential \
    flex \
    grub-common \
    libgmp3-dev \
    libisl-dev \
    libmpc-dev \
    libmpfr-dev \
    texinfo \
    xorriso && \
    rm -rf /var/lib/apt/lists/*

# Add source files
ADD https://ftp.gnu.org/gnu/binutils/binutils-2.44.tar.gz /root/src/
ADD https://ftp.gnu.org/gnu/gcc/gcc-15.1.0/gcc-15.1.0.tar.gz /root/src/
ADD https://sourceware.org/pub/gdb/snapshots/current/gdb.tar.xz /root/src/

WORKDIR /root/src
RUN tar -xvf binutils-2.44.tar.gz && tar -xvf gcc-15.1.0.tar.gz && tar -xvf gdb.tar.xz

# Environment
ARG PREFIX="/opt/cross"
ARG TARGET=i686-elf
ENV PATH="$PREFIX/bin:$PATH"

# Binutils
WORKDIR /root/src/build-binutils
RUN ../binutils-2.44/configure --target=${TARGET} --prefix="${PREFIX}" --with-sysroot --disable-nls --disable-werror && \
    make -j$(nproc) && \
    make install

# GDB
WORKDIR /root/src/build-gdb
RUN ../gdb/configure --target=${TARGET} --prefix="${PREFIX}" --disable-werror && \
    make -j$(nproc) all-gdb && \
    make install-gdb

# GCC
WORKDIR /root/src/build-gcc
RUN ../gcc-15.1.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ \
    --without-headers --disable-hosted-libstdcxx && \
    make -j$(nproc) all-gcc && \
    make -j$(nproc) all-target-libgcc && \
    make -j$(nproc) all-target-libstdc++-v3 && \
    make install-gcc && \
    make install-target-libgcc && \
    make install-target-libstdc++-v3

# Clean up
WORKDIR /
RUN rm -rf /root/src/

CMD ["sh", "-c", "cd /root/os/ && make all"]