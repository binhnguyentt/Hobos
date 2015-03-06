section .text

global start
extern main	        ;kmain is defined in the c file

[bits 16]
start:
	cld
	mov ax, 0
	mov ds, ax
	mov si, msg_a20
	call prints

	; Check for A20 line
	; NOTE: Mostly A20 was enabled already
	; TODO: I haven't write any code for enable A20 (if it was disabled yet)
	cli
	xor ax, ax
	mov ds, ax		; ds = 0x0000

	not ax
	mov es, ax		; es = 0xFFFF

	mov di, 500h
	mov si, 510h

	mov byte [ds:di], 0xAB	; 0x0000:500h
	mov byte [es:si], 0xAC	; 0xFFFF:510h

	cmp byte [ds:di], 0xAC 
	jne .a20_was_enabled

	; A20 was disabled, we need to enable here
	mov si, msg_disabled
	call prints
	jmp .enter_protected_mode

	.a20_was_enabled:
	; A20 was enabled
	mov si, msg_enabled
	call prints

	.enter_protected_mode:
	mov si, msg_protected_mode
	call prints

	lgdt [gdtr]
	mov ax, 10h	; Data selector
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp 08h:start32

; 16bit helpers

prints:
	; ds:si point to message
	lodsb
	cmp al, 0
	je .return
	mov ah, 0Eh
	xor bx, bx
	int 10h
	jmp prints
	.return:
	ret

[bits 32]
start32:
	mov esp, 0x100000	; 1MB
	; I haven't enabled interrupt yet because IDT hadn't been setted up
	; sti
	;mov eax, 0xb8000
	;mov byte [eax], 'A'
	;mov byte [eax + 1], 
	mov dword [0xb8000], 0x07690748 ; Output Hi message
	jmp $

msg_a20: 			db 'Checking for A20 line ...', 0
msg_disabled:		db 'Disabled', 13, 10, 0
msg_enabled:		db 'Enabled', 13, 10, 0
msg_ok				db 'Ok', 13, 10, 0
msg_protected_mode:	db 'Entering protected mode...', 0

gdt:
	; Null selector
	dw 0x0000		
	dw 0x0000
	db 0x00
	db 0x00
	db 0x00
	db 0x00

	; Code selector
	dw 0xFFFF		; Limit 
	dw 0x0000		; Base low
	db 0x00 		; Base middle
	db 10011000b	; Access: Present, Privilege, Executable, DC, RW, Access
	db 11001111b 	; Flag: Granularity, Size - Limit
	db 0x00 		; Base high

	; Data selector
	dw 0xFFFF		; Limit
	dw 0x0000		; Base low
	db 0x00 		; Base middle
	db 10010010b	; Access
	db 10001111b 	; Flag - limit
	db 0x00 		; Base high

gdtr:
	dw (gdtr - gdt - 1)
	dd gdt
