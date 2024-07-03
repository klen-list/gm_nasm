default rel
section .text

extern Msg

global gmod13_open
global gmod13_close

gmod13_open:
	push msg ; arg1 - "Hello from Netwide Assembler!\n\0"
	call Msg ; Call Msg from tier0
	add esp, 4 ; Clear arg1 from stack

	mov eax, 0 ; return 0
	ret
gmod13_close:
	mov eax, 0 ; return 0
	ret

section .rodata
	msg: db "Hello from Netwide Assembler!", 10, 0