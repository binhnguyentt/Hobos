section .text

global start
extern main	        ;kmain is defined in the c file

[bits 16]
start:
	; Check for A20 line
	cli
	xor ax, ax
	mov ds, ax

	not ax
	mov es, ax

	mov di, 500h
	mov si, 510h

	mov byte [ds:di], 0xAB
	mov byte [es:si], 0xAC

	cmp byte [ds:si], 0xAC 
	jne .a20_enabled

	; Enable A20 Here

	.a20_enabled:
	
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
  	;jmp 0:main

[bits 32]
start32:
	mov esp, 0x100000	; 1MB
	; I haven't enabled interrupt yet because IDT hadn't been setted up
	; sti
	;mov eax, 0xb8000
	;mov byte [eax], 'A'
	;mov byte [eax + 1], 
	mov dword [0xb8000], 0x07690748
	jmp $

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
