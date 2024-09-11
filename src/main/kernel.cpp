/** @file
 * denOS kernel
 * Created by denis0001-dev on https://gitverse.ru/denis0001-dev/denOS/content/master/src/main/kernel.cpp
 * Version 0.7.12
 * Compiling, linking, and building commands from https://wiki.osdev.org/Bare_Bones
 * DO NOT EDIT OR REMOVE THIS HEADER.
 */

// ReSharper disable CppUnusedIncludeDirective
#include <limits.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

// Check if the compiler thinks you are targeting the wrong operating system.
#if defined(__linux__)
#error You are not using a cross-compiler, you will most certainly run into trouble
#endif

// This kernel will only work for the 32-bit ix86 targets.
#if !defined(__i386__)
#error This kernel needs to be compiled with a ix86-elf compiler
#endif

extern "C" void kernel_main(void) {
	// kernel code
}