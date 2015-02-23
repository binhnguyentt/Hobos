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

	; Note: edx:eax stores LBA to root dir
	; LBA's unit is sector (not byte)

	; Read sectors
	mov [lba_addr], eax		; LBA-low
	mov [lba_addr + 4], edx	; LBA-high
	mov bl, [stpc]			; Num of sectors
	xor bh, bh
	mov [num_sector], bx

	mov si, read_packet
	mov ah, 0x42
	pop dx					; Get drive number pushed before
	int 0x13

	jc short .error
	jmp .parse_rootdir

	.error:
		mov si, errmsg
		call prints
		jmp .over_err

	.parse_rootdir:
		; At this time, first dir cluster is loaded to 0x0:0x8000
		mov si, 0x8000
		
		.loop:
			; End of list?
			; TODO: I still not check for end-of-cluster yet
			; so, if directory length over 1 cluster, this will cause error
			cmp byte [si], 0
			je .go_out

			; Is that a deleted entry?
			cmp byte [si], 0x5e
			je .go_out

			push si
			mov di, si
			add di, 11

			; Check for valid entry?
			cmp byte [di], 0xF	; Fat32 LFN
			
			; This is Fat32 LFN, skip for now
			je .next_entry

			; Here, si point to 8.3 name of entry
			mov dx, si
			mov di, kernel
			mov cx, 11
			repe cmpsb
			jne .not_match

			; Got file Kernel.bin
			mov si, dx
			xor bl, bl
			mov byte [di], bl
			call prints

			.not_match:
			mov si, dx 	; Restore si

			; xor bx, bx
			; mov byte [di], bl
			; call prints

			.next_entry:
			pop si
			add si, 32
			jmp .loop

		.go_out:
		jmp $

		; jmp 0x8000
	.over_err:
	
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

errmsg:	db 'Cant read sector', 0
kernel: db 'KERNEL  BIN'

read_packet:
	db 16		; Sizeof packet
	db 0		; Zero
num_sector:
	dw 1		; Number of sectors to read (max 127 on some bioses)
				; int 13h reset this to actual readed sectors
addr:
	dw 0x8000	; Offset
	dw 0x0		; Segment
lba_addr:
	dd 1
	dd 0

	times 510 - ($-$$) db 0
	db 0x55
	db 0xaa

; Next sector for test only
cli
hlt

dd 1234567890

times 2048 - ($-$$) db 0
