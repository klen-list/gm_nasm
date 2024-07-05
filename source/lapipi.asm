; Lapipi - Lua API performance increase
; Based on __fastcall -> ecx, edx, stack
section .text

extern lua_pushnil

global init_lapipi
global lpi_pushnumber
global lpi_growstack1

init_lapipi:
	; too lazy to rewrite lj_state_growstack code
	; btw it already __fastcall (mb bc inline)
	; so just lets store addr, its simple
	mov eax, lua_pushnil ; ptr = lua_pushnil
	add eax, 0x25 ; offset to end of jmp instruction
	sub eax, 0x1f65 ; static offset from jmp to lj_state_growstack1
	mov [lpi_growstack1], eax
	ret
	; Code that i use before understand that offset is STATIC:
	;add eax, 33 ; ptr = ptr + offset to jmp
	;mov ecx, [eax] ; *ptr
	;neg ecx ; interpret as a signed 32-bit value
	;add eax, 4 ; 4 bytes of addr
	;sub eax, ecx ; get final jmp target addr

; Rewrite lua_pushnumber
; esi - lua_State pointer, double - stack top (esp)
lpi_pushnumber:
	mov eax, [ecx+20] ; eax = L->top (TValue*)
	; C: L->top->n = n
	movq xmm0, [esp+4] ; Copy double to SIMD register
	movq [eax], xmm0 ; Copy double from SIMD register to L->top
	; C: if (__builtin_expect(!!(L->top->n != L->top->n), 0))
	fld qword [eax] ; Copy double from eax to FPU stack
	fucomip st0, st0 ; L->top NaN check
	jp .canon_nan
.stack_check:
	; C: if (++L->top >= ((TValue*)(L->maxstack).ptr32)) lj_state_growstack(L, 1)
	add eax, 8 ; ++L->top - up a stack top pointer
	mov [ecx+20], eax ; apply up
	cmp eax, [ecx+24] ; L->top, L->maxstack ; check if stack grow needed
	jnb .grown_stack1
	rep retn ; Specific branch prediction fix for AMD K10 CPUs
.grown_stack1:
	; tip: "retn" inside lj_state_growstack use "call lpi_pushnumber" return address
	; bc we are not adding smth to stack there, so "jmp" can be end of function too
	jmp [lpi_growstack1]
.canon_nan: ; Canonicalize injected NaNs.
	; C: L->top->u64 = 0xfff80000 << 32
	mov dword [eax], 0
	mov dword [eax+4], 0xfff80000 
	jmp .stack_check

; use lpi_* with "call [lpi_blah]" or "jmp [lpi_blah]"
section .data
	; ecx - lua_State
	; Lazy analog of lj_state_growstack, with "mov edx, 1"
	lpi_growstack1: dd 0 ; lj_state_growstack1