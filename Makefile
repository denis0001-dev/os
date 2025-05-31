# OS target architecture
TARGET = i686-elf
# Cross-compiler root directory
PREFIX = /opt/cross

# Tools locations
CC = $(PREFIX)/bin/$(TARGET)-g++ # C++ compiler
AS = $(PREFIX)/bin/$(TARGET)-as # Assembly compiler

# Set the OPT variable according to the DEBUG_BUILD environment variable
ifeq (${DEBUG_BUILD}, true)
	# For debugging purposes, the optimization should be disabled
	# because it will complicate debugging by removing some variables.
	# But this method reduces the performance of the kernel.
	OPT = 0
	EXTRAPARAMS_CC = -g -DDEBUG=true
else
	# For normal builds, the optimization is enabled, because
	# the kernel should be as fast as possible.
	OPT = 2
endif

EXTRAPARAMS_CC += -ffreestanding -O$(OPT) -Wall -Wextra -fno-exceptions -fno-rtti

# Source
INDIR = $(shell realpath .)/src/main
# Temporary directory for files during build, after it the temp files
# will be deleted. After that, the folder will contain the kernel
# binary "denOS.bin" and the ISO "denOS.iso".
OUTDIR = $(shell realpath .)/build
PROJDIR = $(shell realpath .)

# Declare some environment variables
setup:
	echo "Declaring global variables..."
	export TARGET=$(TARGET)
	export PREFIX=$(PREFIX)
	export PATH="$(PREFIX)/bin:$PATH"
	mkdir -p $(OUTDIR)

# Clean all files.
clean: clean_all

# Clear the build directory, including the kernel binary and the ISO.
clean_all:
	rm -rf $(INDIR)/*.o $(OUTDIR)/*

# Delete the temporary files needed only to build the kernel,
# excluding the kernel binary and the ISO.
clean_tmp_files:
	rm -rf $(OUTDIR)/boot.o $(OUTDIR)/kernel.o $(OUTDIR)/boot_clean.s $(OUTDIR)/iso/

# Clear the build directory, declare variables, compile boot, kernel,
# link the object files produced by the compilers, check that the kernel
# is valid, make the ISO, clean the temporary files.
all: shell clean setup boot kernel link check iso

# Build the OS, launch it in QEMU with debugging support.
qemu-nocompile:
	qemu-system-i386 -cdrom $(OUTDIR)/denOS.iso -s -m 1G

qemu: all qemu-nocompile

# Compile the bootstrap assembly, needed to properly initialize
# the processor, and launch the high-level kernel in C++.
boot:
	echo "Compiling boot..."
	sed -E 's/;.*$$//g;t' < $(INDIR)/boot.s > $(OUTDIR)/boot_clean.s
	$(AS) $(OUTDIR)/boot_clean.s -o $(OUTDIR)/boot.o

# Compile the high-level kernel using the C++ compiler.
# This also adds debugging symbols to the kernel, so
# it can be debugged using GDB.
kernel:
	echo "Compiling kernel..."
	$(CC) -c $(INDIR)/kernel.cpp -o $(OUTDIR)/kernel.o $(EXTRAPARAMS_CC)

# Check the the kernel is a valid x86 Multiboot kernel.
check:
	grub-file --is-x86-multiboot $(OUTDIR)/denOS.bin

# Link all the object files together.
# This process uses the linker.ld file located in the
# source directory to properly link the kernel to
# make it bootable with Multiboot.
link:
	echo "Linking..."
	$(CC) -T $(INDIR)/linker.ld -o $(OUTDIR)/denOS.bin -ffreestanding -O2 -nostdlib $(OUTDIR)/*.o -lgcc

# Make the ISO with the bootloader GRUB.
iso:
	mkdir -p $(OUTDIR)/iso/boot/grub
	cp $(OUTDIR)/denOS.bin $(OUTDIR)/iso/boot/denOS.bin
	cp $(PROJDIR)/grub.cfg $(OUTDIR)/iso/boot/grub/grub.cfg
	cd $(OUTDIR)/iso
	grub-mkrescue -o $(OUTDIR)/denOS.iso $(OUTDIR)/iso

shell:
