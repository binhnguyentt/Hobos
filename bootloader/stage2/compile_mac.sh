#!/bin/bash

~/Desktop/Cross64/bin/x86_64-elf-gcc -c -g -Os -m32 -march=i686 -ffreestanding -Wall -Werror -I. -o main.o main.c
nasm -f elf stage2.asm -o stage2.o
~/Desktop/Cross64/bin/x86_64-elf-ld -static -Tlinker.ld
