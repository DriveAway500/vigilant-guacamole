#!/bin/sh
nasm -f elf64 output.asm -o output.o
ld output.o -o bonoutput
rm output.o
./bonoutput