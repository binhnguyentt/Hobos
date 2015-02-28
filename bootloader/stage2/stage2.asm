section .text

global start
extern main	        ;kmain is defined in the c file

start:
  jmp 0:main
