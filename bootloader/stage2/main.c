asm(".code16gcc\n");

void __attribute__ ((regparm(3))) print(const char *s){
	while(*s) {
		__asm__ __volatile__ ("int  $0x10" 
			:
			: "a"(0x0E00 | *s), "b"(7));
		 s++;
	}
}

void main() {
	print("Congrat!");	
	while(1){};
}
