; Hobby Operating System
; Copyright 2015 Binh Nguyen


; Memory map
; 0x500: Global variables

ROOT_DIR_LBA	equ 0x500			; 8 bytes
DRIVE_NUMBER	equ (0x500 + 0x08)	; 1 byte

STAGE2_OFFSET	equ 0x600
ROOTDIR_OFFSET	equ 0x8000
