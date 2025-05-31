FROM ubuntu:22.04

#############
# Arguments #
#############
ARG PREFIX="/opt/cross"
ARG TARGET=i686-elf
ENV PATH="$PREFIX/bin:$PATH"


#########################
# Download dependencies #
#########################
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    bison build-essential crossbuild-essential-i386 flex gawk git \
    libgmp3-dev libisl-dev libmpc-dev libmpfr-dev mtools mawk texinfo xorriso  \
    python3 pkg-config patch gettext autoconf autopoint automake libtool \
    glibc-source wget && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /root/src && cd /root/src && \
    wget --no-check-certificate https://ftp.gnu.org/gnu/binutils/binutils-2.44.tar.gz && \
    wget --no-check-certificate https://ftp.gnu.org/gnu/gcc/gcc-15.1.0/gcc-15.1.0.tar.gz && \
    wget --no-check-certificate https://sourceware.org/pub/gdb/snapshots/current/gdb.tar.xz && \
    wget --no-check-certificate https://ftp.gnu.org/gnu/grub/grub-2.12.tar.gz && \
    tar -xvf binutils-2.44.tar.gz && \
    tar -xvf gcc-15.1.0.tar.gz && \
    tar -xvf gdb.tar.xz && \
    tar -xvf grub-2.12.tar.gz


##############################
# Compile dependency sources #
##############################

# Binutils
RUN mkdir -p /root/src/build-binutils && cd /root/src/build-binutils && \
    ../binutils-2.44/configure --target=${TARGET} --prefix="${PREFIX}" --with-sysroot --disable-nls --disable-werror && \
    make -j$(nproc) && \
    make install

# GDB
RUN mkdir -p /root/src/build-gdb && cd /root/src/build-gdb && \
    ../gdb-*/configure --target=${TARGET} --prefix="${PREFIX}" --disable-werror && \
    make -j$(nproc) all-gdb && \
    make install-gdb

# GCC
RUN mkdir -p /root/src/build-gcc && cd /root/src/build-gcc && \
    ../gcc-15.1.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ \
    --without-headers --disable-hosted-libstdcxx && \
    make -j$(nproc) all-gcc && \
    make -j$(nproc) all-target-libgcc && \
    make -j$(nproc) all-target-libstdc++-v3 && \
    make install-gcc && \
    make install-target-libgcc && \
    make install-target-libstdc++-v3

# GRUB
RUN mkdir -p /root/src/grub-2.12 && cd /root/src/grub-2.12 && \
    mv /usr/bin/mawk /usr/bin/mawk.bak && ln /usr/bin/gawk /usr/bin/mawk && \
    ./autogen.sh && \
    ./configure --host=i686-linux-gnu \
    --prefix=/usr/local \
    --target=i686-linux-gnu \
    --with-platform=pc \
    --disable-nls \
    --disable-werror \
    --disable-efiemu && \
    echo "depends bli part_gpt" > grub-core/extra_deps.lst && \
    make -j$(nproc) && \
    make install && \
    rm /usr/bin/mawk && mv /usr/bin/mawk.bak /usr/bin/mawk

# Cross compiler fix
RUN mkdir -p /lib/i386-linux-gnu && cd /lib/i386-linux-gnu && \
    ln /usr/i686-linux-gnu/lib/ld-linux.so.2 /lib/ld-linux.so.2 && \
    ln /usr/i686-linux-gnu/lib/libc.so.6 . && \
    ln /usr/i686-linux-gnu/lib/libgcc_s.so.1 . && \
    ln /usr/i686-linux-gnu/lib/libstdc++.so.6 . && \
    ln /usr/i686-linux-gnu/lib/libm.so.6 .


############
# Clean up #
############
RUN rm -rf /root/src/


######################
# Command to execute #
######################
CMD ["sh", "-c", "cd /root/os/ && make all"]