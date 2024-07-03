default rel
section .text

extern lua_pushnumber
extern lua_setfield
extern lua_pushcclosure
extern lua_tolstring 

global gmod13_open
global gmod13_close

gmod13_open: ; Todo: optimize stack use like lua_function
	push ebx
	call gen_crc_table
	pop ebx

	push 0 ; arg3 - 0 ; always zero in lua_pushcfunction
	push lua_function ; arg2 - pointer to function
	push dword [esp+12] ; arg1 - lua_State (2arg+3arg+ReturnAdr)
	call lua_pushcclosure ; int __cdecl lua_pushcclosure(int*, int(*)(int*), char*)
	add esp, 12
	
	push crc32_index ; arg3 - "CRC32\0"
	push -10002 ; arg2 - Lua global table index
	push dword [esp+12] ; arg1 - lua_State (2arg+3arg+ReturnAdr)
	call lua_setfield ; int __cdecl lua_setfield(int*, int, char*)
	add esp, 12

	mov eax, 0 ; return 0
	ret
gmod13_close:
	mov eax, 0 ; return 0
	ret
lua_function:
	push ebx
	sub esp, 16
	mov esi, [esp+24] ; lua_State

	mov [esp], esi ; arg1 - lua_State
	mov dword [esp+4], 1 ; arg2 - Index in lua stack (1)
	mov [esp+8], esp
	add dword [esp+8], 12 ; arg3 - Pointer to size_t (dword)
	call lua_tolstring ; After call eax contains a pointer to string

	mov edi, [esp+12] ; Copy size_t to edi (string len in .crc32)
	jmp .crc32 ; Do a CRC calc, jmp for remove tails, bc call slower
.after_crc:
	movd xmm0, ebx ; Copy 32-bit result to 64-bit SIMD register
	movq [esp], xmm0 ; After this - copy to stack (8 bytes)
	fild qword [esp] ; Load 8 bytes from stack to FPU, for double convertion
	fstp qword [esp+4] ; Extract 8 bytes from FPU to stack
	mov [esp], esi ; Copy lua_State to stack top
	call lua_pushnumber ; int __cdecl lua_pushnumber(int*, double)

	add esp, 16
	pop ebx
	mov eax, 1 ; return 1
	ret
; eax - pointer to string, edi - string len, ebx - result
.crc32:
	mov ebx, 0xffffffff ; int crc = 0; crc = crc ^ 0xffffffff
.str_loop:
	mov edx, [eax] ; a = *str
	xor edx, ebx ; a = crc ^ a
	and edx, 0xff ; a = a & 0xff
	mov edx, [crc_table+edx*4] ; a = crc_table[a]
	shr ebx, 8 ; crc = crc >> 8
	and ebx, 0x00ffffff ; crc = crc & 0x00ffffff
	xor ebx, edx ; crc = crc ^ a
	inc eax ; str++
	dec edi ; --i
	jnz .str_loop; while (i != 0)
.done:
	xor ebx, 0xffffffff ; return crc ^ 0xffffffff
	jmp .after_crc
gen_crc_table: ; Todo: optimize
	mov ecx, 0 ; bytes counter
.calc_byte:
	cmp ecx, 256
	jz .done ; bytes counter == 256
	mov edx, ecx ; byte = counter
	mov edi, 0 ; bits counter
.calc_bit:
	cmp edi, 8
	jz .goto_next_byte ; bits counter == 8
	inc edi
	mov eax, edx ; temp = byte
	and eax, 1 ; get a last bit
	shr edx, 1
	mov ebx, edx
	xor ebx, [poly]
	cmp eax, 1 ; if last bit is not 1 
	jnz .calc_bit ; then skip apply poly XOR to crc 
	mov edx, ebx ; else apply
	jmp .calc_bit
.done:
	ret
.goto_next_byte:
	mov [crc_table+ecx*4], edx
	inc ecx
	jmp .calc_byte

section .bss
	crc_table: resd 256 
section .rodata
	poly: dd 0xEDB88320
	crc32_index: db "CRC32", 0