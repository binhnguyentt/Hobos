; Read disk with:
; edx:eax 	~> LBA (sector) xxxx
; cl 		~> Drive number xxx 
; bx 		~> Number of sectors to read xxxx

; dl		~> Drive number
; cx		~> Number of sectors to read
; es:si		~> Store LBA (qword)
; es:di		~> Dest offset

; Return:
; ah = 0 ~> ok
; ah = 1 ~> err
read_disk:
	mov [num_sector], cx		; Num of sectors
	
	mov ecx, [es:si]			; LBA low
	mov [lba_addr], ecx
	
	mov ecx, [es:si + 4]		; LBA high
	mov [lba_addr + 4], ecx
	
	mov word [addr], di			; Offset
	mov word [addr + 2], es

	mov si, io_packet
	mov ah, 0x42
	; mov dl, cl
	int 0x13
	
	jc .carry
	xor ah, ah
	jmp short .return

	.carry:	; error
	mov ah, 1

	.return:
	ret

io_packet:
	db 16		; Sizeof packet
	db 0		; Alway zero
num_sector:		; Number of sectors to read (max 127 on some bioses)
	dw 1		; int 13h reset this to actual readed sectors
addr:
	dw 0x8000	; Offset
	dw 0x0		; Segment
lba_addr:
	dd 1
	dd 0
