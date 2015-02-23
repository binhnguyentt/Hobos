[org 0x9000]

mov al, 'K'
mov ah, 0x0E
xor bx, bx
int 0x10

cli
hlt
