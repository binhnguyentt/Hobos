ENTRY(main);
/* OUTPUT_ARCH(i386) */
SECTIONS
{
    . = 0x600;
    .text : AT(0x600)
    {
        _text = .;
        *(.text);
        _text_end = .;
    }
    
    .data :
    {
        _data = .;
        *(.bss);
        *(.bss*);
        *(.data);
        *(.rodata*);
        *(COMMON)
        _data_end = .;
    }
    
    /* 
    	Since this is a stage2, we don't need this anymore
    */
    
    /*
    .sig : AT(0x7DFE)
    {
        SHORT(0xaa55);
    } 
    */
    
    /DISCARD/ :
    {
        *(.note*);
        *(.iplt*);
        *(.igot*);
        *(.rel*);
        *(.comment);
    }
}
