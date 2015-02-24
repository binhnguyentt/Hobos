prints: ; ds:si point to null-terminate string
	; cld
	lodsb
	cmp al, 0
	je .return
	call printc
	jmp prints

	.return:
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
