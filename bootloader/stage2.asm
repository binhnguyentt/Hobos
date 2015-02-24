[org 0x500]

mov si, stage2
loop_here:
	lodsb
	cmp al, 0
	je .out
	
	mov ah, 0eh
	int 10h
	jmp loop_here
	
	.out:
	
	jmp $


stage2:
	db 'Welcome to stage 2 bootloader!', 0
