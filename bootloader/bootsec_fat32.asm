; Part of Hobby Operating System
; Fat32 bootloader
; Copyright 2015 Binh Nguyen



[org 0x7c00]
[bits 16]

jmp over_bpb
nop

db 'mkfs.fat' 	; OEM name
bpst: dw 512	; Bytes per sector
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
	mov ds, ax
	mov es, ax
	mov ss, ax
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
	mul ebx			; edx:eax stores number sectors of fats

	pop ebx			; Get reserved sectors
	pop ecx
	add eax, ebx	; Total = Reserved sectors + FATs sectors
	adc edx, ecx	
	
	; Here: edx:eax stores total number of sectors to root dir (from begining
	; of partition, NOT begining of disk)
	; TODO Calculate LBA fron beginning of disk to work fine on multi-partitions hard disk

	; Note: edx:eax stores LBA to root dir
	; LBA's unit is sector (not byte)

	mov [ROOT_DIR_LBA], eax	; Store root directory's LBA for later usage

	; Read sectors
	mov [ROOTDIR_OFFSET], eax	; Temporary stores LBA here
	mov [ROOTDIR_OFFSET + 4], edx
	mov si, ROOTDIR_OFFSET

	pop dx						; Drive number
	mov [DRIVE_NUMBER], dl		; Store drive number for later use

	mov ax, ROOTDIR_OFFSET		; Offset
	mov di, ax

	xor ch, ch
	mov cl, [stpc]				; Read 1 cluster

	call read_disk				; Read it

	cmp ah, 0 					; Are we success?
	je short .parse_rootdir

	; jmp .parse_rootdir

	; .error:
	mov al, ERR_CANT_LOAD_ROOTDIR
	call printc
	jmp halt

	.parse_rootdir:
		; At this time, first dir cluster is loaded to 0x0:0x8000
		mov si, ROOTDIR_OFFSET
		
		.loop:
			; End of list?
			; TODO: I still not check for end-of-cluster yet
			; so, if directory length over 1 cluster, this will cause error
			cmp byte [es:si], 0
			je .go_out

			; Is that a deleted entry?
			cmp byte [es:si], 0x5e
			je .go_out

			push si
			mov di, si
			add di, 11			; Seek to attribute

			; Check for valid entry?
			cmp byte [di], 0xF	; Fat32 LFN
			
			; This is Fat32 LFN, skip for now
			je .next_entry

			; Here, si point to 8.3 name of entry
			mov dx, si
			mov di, stage2
			mov cx, 11			; In 8.3 format, we need 8 + 3 = 11 characters
			repe cmpsb
			jne .next_entry

			; Got file stage2 (8.3 format)
			mov si, dx	; si still point to directory entry

			add si, 26	; seek to cluster low
			; Now es:si store cluster of stage2
			; TODO: need combine with cluster high

			xor edx, edx
			xor ecx, ecx
			xor eax, eax

			mov ax, [si]
			sub ax, 2						; Cluster begin from 2
			mov cl, [stpc]
			mul ecx							; edx:eax store LBA to kernel.bin (from LBA root dir)

			mov ecx, [ROOT_DIR_LBA]			; Final LBA = file LBA + root dir LBA
			add eax, ecx
			adc edx, 0						; edx:eax store LBA

			mov [STAGE2_OFFSET], eax		; Temporate store LBA address here
			mov [STAGE2_OFFSET + 4], edx
			mov si, STAGE2_OFFSET

			mov di, STAGE2_OFFSET			; Load to this address

			xor ch, ch
			mov cl, [stpc]					; Load one cluster

			mov dl, [DRIVE_NUMBER]			; Drive numer we have stored

			call read_disk

			cmp ah, 0
			je .okay

			; Error
			mov al, ERR_CANT_LOAD_STAGE2
			call printc
			jmp halt
			
			.okay:
			; Stage2 is loaded (Yay)
			; TODO: si till on stack but does it need to care?
			jmp STAGE2_OFFSET

			.next_entry:
			pop si
			add si, 0x20	; Directory entry takes 32 bytes length
			jmp .loop

		.go_out:
		mov al, ERR_STAGE2_NOT_FOUND
		call printc
		jmp halt


; Print a character in al to screen
printc:
	mov ah, 0x0e
	xor bx, bx
	int 0x10
	ret

; Stop the processor
halt:
	cli
	hlt
	jmp halt

%include 'disk_svc.asm'
%include 'memory.asm'

; Error codes
ERR_CANT_LOAD_ROOTDIR		equ '1'
ERR_CANT_LOAD_STAGE2		equ	'2'
ERR_STAGE2_NOT_FOUND		equ '3'

; rootdr: dq 0						; Root directory begin
; driven: db 0						; Drive number

stage2: db 'STAGE2     '			; Stage2 file name in 8.3 format

times 510 - ($-$$) db 0
dw 0xAA55
