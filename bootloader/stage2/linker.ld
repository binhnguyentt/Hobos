ENTRY(start)
OUTPUT_FORMAT(binary)
OUTPUT_ARCH(i386)
OUTPUT(stage2)

SECTIONS {
	. = 0x600;
	
	.text : AT(0x600) 
	{
		stage2.o(.text);
		main.o(.text)
	}
	
	.data :
	{
		*(.bss);
        *(.bss*);
        *(.data);
        *(.rodata*);
        *(COMMON)
	}
}
