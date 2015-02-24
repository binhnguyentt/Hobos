[org 0x9000]

mov si, kernel_hello

print:
lodsb
cmp al, 0
je .out

mov ah, 0x0E
xor bx, bx
int 0x10
jmp print

.out:
cli
hlt


kernel_hello:
db 'Hello from KERNEL \m/', 0
