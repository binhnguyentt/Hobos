[org 0x7c00]

jmp over_bpb
nop

db 'mkfs.fat' 		; OEM name
bpst: dw 512		; Bytes per sector
stpc: db 8		; Sectors per cluster
rsts: dw 32		; Reserved sectors <~~
nbof: db 2		; Number of FAT table
dw 0			; Number of root directory (N/A for Fat32)
dw 0			; Number of sectors in partition (if lt 32M - N/A for fat32)
db 0xF8			; Media descriptor (0xF8 is hard disk)
dw 0			; Number of sectors per FAT (fat 16, 12 - N/A for fat32)
dw 0			; Number of sectors per track <~~
dw 0			; Number of heads <~~
dd 0			; Number of hidden sectors
dd 0			; Number if hidden sectors in partition (if gt 32M)

; Fat32 bpb
stpf: dd 299	; Number of sectors per FAT
dw 0			; Flags
dw 0			; Version of fat32
csrd: dd 2		; Cluster of starting root directory
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

	push dx			; driver number

	; Read FAT table to memory
	; TODO

	; Get root dir

	xor ebx, ebx
	mov bx, [rsts]	; reserved sectors (word)
	mov eax, [stpf]	; number of sectors per fat (dword)
	xor edx, edx
	xor ecx, ecx
	mov cl, [nbof]
	mul ecx			; edx:eax stores number of sectors of FAT tables

	add eax, ebx	; 
	adc edx, 0		; edx:ebx stores number of sectors to data area
	push edx
	push eax


	; Get num of sector to root dir
	
	mov eax, [csrd]	; cluster of start root dir
	sub eax, 2
	xor ebx, ebx
	mov bl, [stpc]	; sectors per cluster
	mul ebx			; edx:eax stores number of sector to root dir

	pop ebx
	pop ecx
	add eax, ebx
	adc edx, ecx	; edx:eax stores total number of sectors to root dir (from begining
					; of partition, NOT begining of disk)

	mov bx, [bpst]	; bytes per sector
	mul ebx			; edx:eax stores LBA to root dir (from begining of partition,
					; NOT from begining of disk)

	; push eax
	; mov ecx, edx
	; call printbn
	; pop ecx
	; call printbn


	mov si, drive
	call prints

	xor ecx, ecx
	pop cx
	xor ch, ch
	call printbn

	; push eax
	; mov si, lba
	; call prints

	; pop ecx
	; call printbn

	; Print somethings

	; mov si, str
	; call prints

	; mov ecx, over_bpb - $$
	; call printbn

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

; Print a big number stored in ecx
; Destroy eax, edx registers
printbn:
	cmp ecx, 10
	jge .do_math

	mov al, cl
	call printn
	jmp .return

	.do_math:
		mov eax, ecx
		xor edx, edx ; edx:eax storex 32bit number

		mov ecx, 10
		div ecx 		 ; edx: remainder, eax: quotient
		
		push edx

		; Print the rest
		mov ecx, eax
		call printbn

		; Print the remainder
		pop eax
		call printn
		
	.return:
	ret

str: 	db '. Sizeof bpb is: ', 0
data: 	db 'Num of sectors to data: ', 0
root: 	db 'Number of sectors to root dir: ', 0
lba: 	db 'LBA to root dir: ', 0
drive:	db 'Drive number: ', 0

	times 510 - ($-$$) db 0
	db 0x55
	db 0xaa
	
	
