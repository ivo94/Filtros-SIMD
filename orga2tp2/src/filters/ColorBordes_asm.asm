section .rodata

bluemask: times 4 dd 0x000000FF
greenmask: times 4 dd 0x0000FF00
redmask: times 4 dd 0x00FF0000
transparencia: dd 0xFF000000, 0xFF000000, 0, 0
pixelesblancos: times 4 dd 0xFFFFFFFF
pixelblanco: dd 0xFFFFFFFF
ultimopixel: dd 0xFFFFFFFF, 0, 0, 0,  ;si no anda es al reves
ultimos2pixeles: dd 0xFFFFFFFF, 0xFFFFFFFF, 0, 0

section .text

extern ColorBordes_c
global ColorBordes_asm

ColorBordes_asm:
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	push rbx
	sub rsp, 8

	mov r12, rdi  ;*src
	mov r13, rsi  ;*dst
	mov r14d, edx ;width  (ancho en pixeles)
	mov r15d, ecx ;height (alto)

	;mov rax, r13

	xor rbx, rbx
	mov ebx, r8d   ;row size (ancho en bytes de la fila)

	xor r8d, r8d  ;contador filas
	xor r9d, r9d  ;contador columnas

	movdqu xmm10, [pixelesblancos]
	movdqu xmm11, [bluemask]
	movdqu xmm12, [greenmask]
	movdqu xmm13, [redmask]
	movdqu xmm14, [transparencia]
	movdqu xmm15, [ultimopixel]
	movdqu xmm9, [ultimos2pixeles]
	mov edx, [pixelblanco]


ciclo:

	cmp r8d, 0
	je cuatroPixelesBlancos
	mov edi, r15d  ;el alto
	dec edi
	cmp r8d, edi
	je cuatroPixelesBlancos

	cmp r9d, 0 
	je unPixelBlanco
	mov edi, r14d
	dec edi
	cmp r9d, edi
	je unPixelBlanco

	mov rsi, r12 
	sub rsi, rbx

	movdqu xmm0, [rsi]  ;r12-ancho fila 
	movdqu xmm1, [r12]      ;r12 
	movdqu xmm2, [r12+rbx]  ;r12+ancho fila

	movdqu xmm3, xmm0
	movdqu xmm4, xmm2 

	movdqu xmm5, xmm3
	psubusb xmm3, xmm4
	psubusb xmm4, xmm5
	por xmm3, xmm4

	movdqu xmm4, xmm3

	pand xmm4, xmm15  ;tengo el ultimo pixel
	
	movdqu xmm5, xmm3 ;tercer pixel 
	psrldq xmm5, 4
	pand xmm5, xmm15 

	movdqu xmm6, xmm3 ;segundo pixel
	psrldq xmm6, 8
	pand xmm6, xmm15 

	movdqu xmm7, xmm3 ;primer pixel 
	psrldq xmm7, 12
	pand xmm7, xmm15 

	movdqu xmm8, xmm7  ;pongo primer pixel
	paddusb xmm8, xmm6  ;sumo segundo pixel 
	paddusb xmm8, xmm5  ;sumo tercero

	pslldq xmm8, 4

	paddusb xmm8, xmm6
	paddusb xmm8, xmm5
	paddusb xmm8, xmm4

	;ahora las operaciones horizontales

	movdqu xmm3, xmm0
	movdqu xmm4, xmm0

	pand xmm4, xmm9
	psrldq xmm3, 8

	movdqu xmm5, xmm3
	psubusb xmm3, xmm4
	psubusb xmm4, xmm5
	por xmm3, xmm4

	paddusb xmm8, xmm3

	movdqu xmm3, xmm1
	movdqu xmm4, xmm1

	pand xmm4, xmm9
	psrldq xmm3, 8

	movdqu xmm5, xmm3
	psubusb xmm3, xmm4
	psubusb xmm4, xmm5
	por xmm3, xmm4

	paddusb xmm8, xmm3
	
	movdqu xmm3, xmm2
	movdqu xmm4, xmm2

	pand xmm4, xmm9
	psrldq xmm3, 8
	
	movdqu xmm5, xmm3
	psubusb xmm3, xmm4
	psubusb xmm4, xmm5
	por xmm3, xmm4

	paddusb xmm8, xmm3

	paddusb xmm8, xmm14   ;seteamos transparencia
	
	movq [r13], xmm8

	add r12, 8
	add r13, 8
	add r9d, 2

	jmp ciclo


unPixelBlanco:
	mov [r13], edx
	inc r9d
	add r13, 4
	cmp r8d, 1
	je ver
seguir2:
	add r12, 4
seguir:	
	cmp r9d, r14d
	jne ciclo
	xor r9d, r9d
	inc r8d
	jmp ciclo

ver: 
	cmp r9d, 1
	je seguir
	jmp seguir2


cuatroPixelesBlancos:
	movdqu [r13], xmm10
	add r9d, 4
	add r12, 16
	add r13, 16
	cmp r9d, r14d
	jne ciclo
	xor r9d, r9d
	inc r8d 
	cmp r8d, r15d
	jne ciclo

	add rsp, 8
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret



; La proxima linea debe ser replazada por el codigo asm
;jmp ColorBordes_c


