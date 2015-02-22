[org 0x7c00]

jmp over_bpb
nop

db 'mkfs.fat' 	; OEM name
dw 512			; bytes per sector
db 8			; sectors per cluster
dw 32			; Reserved vectors <~~
db 2			; Number of FAT table
dw 0			; Number of root directory (N/A for Fat32)
dw 0			; Number of sectors in partition (if lt 32M - N/A for fat32)
db 0xF8			; Media descriptor (0xF8 is hard disk)
dw 0			; Number of sectors per FAT (fat 16, 12 - N/A for fat32)
dw 0			; Number of sectors per track <~~
dw 0			; Number of heads <~~
dd 0			; Number of hidden sectors
dd 0			; Number if hidden sectors in partition (if gt 32M)

; Fat32 bpb
dd 0			; Number of sectors per FAT
dw 0			; Flags
dw 0			; Version of fat32
dd 2			; Cluster of root directory
dw 1			; Sector number of file system information sector
dw 6			; Sector number of backup boot sector
times 12 db	0	; Reserved
db 0x80			; Logical driver number
db 0			; Unused
db 0x29			; Extended signature
dd 0			; Serial number
db 'NBOS       '; Label
db 'FAT32   '	; Fat name (8 bytes)

over_bpb:
	jmp 0:start
	
start:
	cli
	xor ax, ax
	mov ss, ax
	mov ds, ax
	mov sp, 0x7c00
	sti

	mov si, str
	call prints

	jmp $

prints: ; ds:si point to null-terminate string
	; cld
	lodsb
	cmp al, 0
	je .return
	call printc
	jmp prints

	.return:
	ret
	
printc: ; al store character to print
	mov ah, 0x0e
	xor bx, bx
	int 0x10
	ret

printn: ; al store number to print
	add al, '0'
	call printc
	ret

str: db 'This is a string', 0
	times 510 - ($-$$) db 0
	db 0x55
	db 0xaa
	
	
