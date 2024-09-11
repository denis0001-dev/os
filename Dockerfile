FROM ubuntu:latest

#
# Install dependencies
#
RUN apt update
RUN apt upgrade -y
RUN apt install -y build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo libisl-dev

ADD https://ftp.gnu.org/gnu/binutils/binutils-2.44.tar.gz /root/src/
ADD https://ftp.gnu.org/gnu/gcc/gcc-15.1.0/gcc-15.1.0.tar.gz /root/src/
ADD https://sourceware.org/pub/gdb/snapshots/current/gdb.tar.xz /root/src/

WORKDIR /root/src
RUN ls *.gz *.xz | xargs -n1 tar -xvf

#
# Environment
#
ARG PREFIX="/opt/cross"
ARG TARGET=i686-elf
ENV PATH="$PREFIX/bin:$PATH"

# Binutils
WORKDIR /root/src/build-binutils
RUN ../binutils-2.44/configure --target=${TARGET} --prefix="${PREFIX}" --with-sysroot --disable-nls --disable-werror
RUN make -j 10
RUN make install

# GDB
WORKDIR /root/src/build-gdb
RUN ../gdb-17.0.50.20250530/configure --target=${TARGET} --prefix="${PREFIX}" --disable-werror
RUN make -j 10 all-gdb
RUN make -j 10 install-gdb

# GCC
RUN which -- ${TARGET}-as || echo ${TARGET}-as is not in the PATH

WORKDIR /root/src/build-gcc
RUN ../gcc-15.1.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ \
    --without-headers --disable-hosted-libstdcxx
RUN make -j 10 all-gcc
RUN make -j 10 all-target-libgcc
RUN make -j 10 all-target-libstdc++-v3
RUN make install-gcc
RUN make install-target-libgcc
RUN make install-target-libstdc++-v3
