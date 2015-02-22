[org 0x7c00]

jmp over_bpb
nop

db 'mkfs.fat' 	; OEM name
dw 512			; Bytes per sector
stpc: db 8		; Sectors per cluster
rsts: dw 32		; Reserved sectors <~~
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
stpf: dd 0		; Number of sectors per FAT
dw 0			; Flags
dw 0			; Version of fat32
root_clus: dd 2	; Cluster of root directory
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

	; Read FAT table to memory
	; TODO

	; Get root dir
	; mov ax, rsts 	; Reserved sectors
	; xor dx, dx
	; cwd			; dx:ax store reserved sectors
	
	; mov ebx, [stpf]
	; mov cx, bx
	; shr ebx, 16 	; bx:cx store sectors per fat
	xor eax, eax
	mov ax, [rsts]
	mov ebx, [stpf]
	add ebx, eax	; ebx stores num.of sectors to data

	xor eax, eax
	mov eax, [root_clus]
	; mul byte ptr [stpc] 

	add eax, ebx

	; Print somethings

	mov si, str
	call prints

	mov cx, over_bpb - $$
	call printbn

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

; Print a character in al to screen
printc:
	mov ah, 0x0e
	xor bx, bx
	int 0x10
	ret

; Print a small number (< 10) stored in al
printn:
	add al, '0'
	call printc
	ret

; Print a big number stored in cx
; Destroy dl, ax registers
printbn:
	cmp cx, 10
	jge .do_math

	mov al, cl
	call printn
	jmp .return

	.do_math:
		mov ax, cx
		mov dl, 10
		div dl ; ah: remainder, al: quotient
		
		push ax
		xor cx, cx
		mov cl, al
		call printbn
		pop ax
		mov al, ah
		call printn
		
	.return:
	ret

str: db 'Sizeof bpb is: ', 0

	times 510 - ($-$$) db 0
	db 0x55
	db 0xaa
	
	
