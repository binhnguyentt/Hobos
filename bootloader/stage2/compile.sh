#!/bin/bash

gcc -c -g -Os -m32 -march=i686 -ffreestanding -Wall -Werror -I. -o 
stage2.o stage2.c
ld -static -Tlinker.ld -nostdlib --nmagic -o stage2.elf stage2.o -melf_i386
objcopy -O binary stage2.elf stage2
