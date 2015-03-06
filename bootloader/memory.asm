; Hobby Operating System
; Copyright 2015 Binh Nguyen


; Memory map
; 0x500: Uninitialize variables

BSS_ADDR		equ 0x500

; Store LBA of FAT32 root directory
ROOT_DIR_LBA	equ BSS_ADDR			; 8 bytes 

; Drive number: after POST, BIOS stores drive number
; in dl register, we take it and put here for later use (read operation)
DRIVE_NUMBER	equ (BSS_ADDR + 0x08)	; 1 byte

; Stage2 offset
STAGE2_OFFSET	equ 0x600

; We temporary load FAT32 root directory to this address
ROOTDIR_OFFSET	equ 0x8000
