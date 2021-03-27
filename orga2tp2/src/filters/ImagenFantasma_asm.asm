section .rodata

bluemask: times 4 dd 0x000000FF
greenmask: times 4 dd 0x0000FF00
redmask: times 4 dd 0x00FF0000
transparencia: times 4 dd 0xFF000000

constante: dd 0.9, 0.9, 0.9, 0.9

section .text

extern ImagenFantasma_c
global ImagenFantasma_asm

ImagenFantasma_asm:
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	push rbx
	sub rsp, 8

	mov r12, rdi ;puntero src
	mov r13, rsi ;puntero dst
	mov r14d, ecx ; height
	mov r15d, edx ;width

	shr r15d, 2 ;divido por 4 (recorro de a 4 pixeles) 
	shr r14d, 1 ;voy a recorrer de a dos filas

	movdqu xmm10, [bluemask]
	movdqu xmm11, [greenmask]
	movdqu xmm12, [redmask]
	movdqu xmm13, [constante]
	movdqu xmm14, [transparencia]

	xor rdi, rdi ;indice fila = 0
	xor rsi, rsi ;indice columna = 0

	xor rcx, rcx ;indice filaFantasma
	xor rdx, rdx ;indice columnaFantasma

	mov rbx, r12

	xor rax, rax
	mov eax, [rbp+24] ;offsety
	mul r8d ;multiplico por tam fila
	add rbx, rax  ;avanzo las filas

	xor rax, rax
	mov rax, [rbp+16] ;offsetx
	lea rax, [rax*4] ;avanzo las columnas (mult por 4 porque cada pixel mide 4 bytes)
	add rbx, rax

cicloImgFant:

	;En cada ciclo recorro dos pixeles de la imagen fantasma y calculo dos b. Cada uno de estos b afectaran a 4 pixeles de la img original, 
	; ya que la imagen fantasma es el doble de ancho y de alto que la original. (i' = i/2 y j' = j/2).
	; por eso tomo los 2 b y los sumo a derecha y hacia abajo para modificar 8 pixeles de la imagen destino 
	; pxfantasma1 | pxfantasma2 ->   b1  | b2 ->   b1 | b1 | b2 | b2 ->  | b1 | b1 | b2 | b2 |  
	;																	 | b1 | b1 | b2 | b2 |

	; Recorrerá en la imagen fantasma de dos en dos y en la original de a 4 pixeles en columnas y de a 2 en filas


	movdqu xmm0, [r12] ; puntero src + desplazamiento (4 pixeles)
	movdqu xmm15, [r12+r9] ; misma columna en la fila siguiente

	movq xmm1, [rbx+rdx*4]; imagen fantasma

	movdqu xmm3, xmm1
	pand xmm3, xmm10 ;bluemask

	movdqu xmm4, xmm1
	pand xmm4, xmm11 ;greenmask
	psrld xmm4, 8

	paddd xmm3, xmm4  ;sumo azul + 2 verde
	paddd xmm3, xmm4

	movdqu xmm4, xmm1
	pand xmm4, xmm12 ;redmask
	psrld xmm4, 16

	paddd xmm3, xmm4  ;sumo rojo

	psrld xmm3, 2 ;divido por 4. Queda en parte azul
	psrld xmm3, 1 ;divido por 2, porque lo voy a sumar como b/2


	punpckldq xmm3, xmm3  ;los duplico a izquierda -> ....|b1|b2| ->  |b1|b1|b2|b2|

	;Modifico los cuatro pixeles en la fila que estoy

	movdqu xmm5, xmm0 ;muevo el original
	pand xmm5, xmm10 ;saco parte azul
	cvtdq2ps xmm5, xmm5 ;convierto a float
	mulps xmm5, xmm13 ;multiplico por 0.9
	cvttps2dq xmm5, xmm5 ;convierto a int con truncamiento
	paddusb xmm5, xmm3 ;sumo b/2 con saturacion
	movdqu xmm7, xmm5 ;guardo parte azul

	movdqu xmm5, xmm0 ;muevo el original
	pand xmm5, xmm11 ;saco parte verde
	psrld xmm5, 8  ;pongo en parte baja de dwords (parte azul)
	cvtdq2ps xmm5, xmm5 ;convierto a float
	mulps xmm5, xmm13 ;multiplico por 0.9
	cvttps2dq xmm5, xmm5 ;convierto a int con truncamiento
	paddusb xmm5, xmm3 ;sumo b/2 con saturacion
	pslld xmm5, 8 ;vuelvo a poner en lugar green
	paddd xmm7, xmm5

	movdqu xmm5, xmm0 ;muevo el original
	pand xmm5, xmm12 ;saco parte roja
	psrld xmm5, 16  ;pongo en parte baja de dwords (parte azul)
	cvtdq2ps xmm5, xmm5 ;convierto a float
	mulps xmm5, xmm13 ;multiplico por 0.9
	cvttps2dq xmm5, xmm5 ;convierto a int con truncamiento
	paddusb xmm5, xmm3 ;sumo b/2 con saturacion
	pslld xmm5, 16 ;vuelvo a poner en lugar rojo
	paddd xmm7, xmm5

	paddd xmm7, xmm14 ;seteo la transparencia

	;Mismo procedimiento para los 4 pixeles de abajo

	movdqu xmm5, xmm15 ;muevo los pixeles
	pand xmm5, xmm10 ;saco parte azul
	cvtdq2ps xmm5, xmm5 ;convierto a float
	mulps xmm5, xmm13 ;multiplico por 0.9
	cvttps2dq xmm5, xmm5 ;convierto a int con truncamiento
	paddusb xmm5, xmm3 ;sumo b/2 con saturacion
	movdqu xmm8, xmm5 ;guardo parte azul

	movdqu xmm5, xmm15 ;muevo los pixeles
	pand xmm5, xmm11 ;saco parte verde
	psrld xmm5, 8  ;pongo en parte baja de dwords (parte azul)
	cvtdq2ps xmm5, xmm5 ;convierto a float
	mulps xmm5, xmm13 ;multiplico por 0.9
	cvttps2dq xmm5, xmm5 ;convierto a int con truncamiento
	paddusb xmm5, xmm3 ;sumo b/2 con saturacion
	pslld xmm5, 8 ;vuelvo a poner en lugar green
	paddd xmm8, xmm5

	movdqu xmm5, xmm15 ;muevo los pixeles
	pand xmm5, xmm12 ;saco parte roja
	psrld xmm5, 16  ;pongo en parte baja de dwords (parte azul)
	cvtdq2ps xmm5, xmm5 ;convierto a float
	mulps xmm5, xmm13 ;multiplico por 0.9
	cvttps2dq xmm5, xmm5 ;convierto a int con truncamiento
	paddusb xmm5, xmm3 ;sumo b/2 con saturacion
	pslld xmm5, 16 ;vuelvo a poner en lugar rojo
	paddd xmm8, xmm5


	paddd xmm8, xmm14 ;seteo la transparencia

	movdqu [r13], xmm7
	movdqu [r13+r9], xmm8

	add rdx, 2     ;aumento dos columnas
	add r12, 16    ;aumento el puntero en 16 porque recorrí 4 pixeles
	add r13, 16    ;idem
 
	inc esi
	cmp esi, r15d
	jne cicloImgFant


	xor esi, esi  ;reseteo indice columnas 
	xor rdx, rdx  ;idem 
	add rbx, r9   
	add r12, r9   ;salteo una fila
	add r13, r9   ;idem
	
	inc edi			  ;aumento fila 
	cmp edi, r14d	  ;chequeo si terminé
	jne cicloImgFant


finImgFant:

	add rsp, 8
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret


;Otra version

; section .rodata

; ALIGN 16

; blue: db 0x00,0xFF,0xFF,0xFF,0x04,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF

; red: db 0xFF,0xFF,0x02,0xFF,0xFF,0xFF,0x06,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF

; green: db 0xFF,0x01,0xFF,0xFF,0xFF,0x05,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF

; saturate_transp: db 0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

; constant: dd 0.9,0.9,0.0,0.0

; section .text

; ImagenFantasma_asm:
; ;Parámetros
; ;rdi = src
; ;rsi = dst
; ;edx = width
; ;ecx = height
; ;r8d = src_row_size
; ;r9d = dst_row_size
; ;[rbp + 16] = offsetx (después de armar el stack frame)
; ;[rbp + 24] = offsety (después de armar el stack frame)

; 	push rbp
; 	mov rbp, rsp
; 	push r12 
; 	push r13
; 	push r14
; 	push r15
; 	push rbx
; 	sub rsp, 8
; 	xor r10, r10
; 	xor r11, r11
; 	xor r12, r12; r12 = j
; 	xor r13, r13; r13 = i
; 	mov r10d, [rbp + 16]; r10 = offsetx (para evitar acceder muchas veces a memomria)
; 	mov r11d, [rbp + 24]; r11 = offsety
; 	mov r14, rdi; r14 puntero al inicio de la imagen
	
; 	movdqa xmm5, [blue]
; 	movdqa xmm6, [red]
; 	movdqa xmm7, [green]
; 	movdqa xmm10, [constant]
; 	movdqa xmm11, [saturate_transp]


; 	.cicloFilas:
; 		push rcx
; 		push rdx
; 		mov rcx, rdx
; 		shr rcx, 1; rcx = width/2 (porque se opera de a 2 pixeles) 
; 		mov rax, r12
; 		shr rax, 1; rax = j/2
; 		add rax, r11; j/2 + offsety (jj)
; 		mul r8d; rax = jj * row_size (que pasaria si el resultado esta en rdx:rax?)

; 		.cicloColumnas:
; 			movq xmm0, [rdi]; levanta 2 pixeles
; 			mov r15, r13
; 			shr r15, 1; r15 = i/2
; 			add r15, r10; r15 = i/2 + offsetx (ii)
; 			lea rbx, [rax + r15 * 4]
; 			lea rbx, [r14 + rbx]
; 			movd xmm1, [rbx]; ...|A R G B| (indice [jj][ii])
; 			movdqa xmm2, xmm1
; 			movdqa xmm3, xmm1
; 			movdqa xmm4, xmm1
; 			pshufb xmm2, xmm5; ...|0 0 0 B|
; 			pshufb xmm3, xmm6; ...|0 R 0 0|
; 			pshufb xmm4, xmm7; ...|0 0 G 0|
; 			psrld xmm3, 16
; 			psrld xmm4, 8

; 			paddd xmm2, xmm3; en este caso sumar con enteros es lo mismo que sumar con floats
; 			paddd xmm2, xmm4
; 			paddd xmm2, xmm4
; 			psrld xmm2, 3
; 			punpckldq xmm2, xmm2; ...|b/2|b/2|

; 			movq xmm3, xmm0; ...|A1 R1 G1 B1|A0 R0 G0 B0|
; 			movq xmm4, xmm0; ...|A1 R1 G1 B1|A0 R0 G0 B0|
; 			movq xmm8, xmm0; ...|A1 R1 G1 B1|A0 R0 G0 B0|
; 			pshufb xmm3, xmm5; xmm3 = ...|0 0 0 B1|0 0 0 B0|
; 			pshufb xmm4, xmm6; 
; 			psrld xmm4, 16; xmm4 = ...|0 0 0 R1|0 0 0 R0|
; 			pshufb xmm8, xmm7
; 			psrld xmm8, 8; xmm8 = ...|0 0 0 G1|0 0 0 G0|

; 			cvtdq2ps xmm3, xmm3; ...|B1(float)|B0(float)|
; 			cvtdq2ps xmm4, xmm4; ...|R1(float)|R0(float)|
; 			cvtdq2ps xmm8, xmm8; ...|G1(float)|G0(float)|
; 			mulps xmm3, xmm10; ...|0.9*B1|0.9*B0|
; 			mulps xmm4, xmm10; ...|0.9*R1|0.9*R0|
; 			mulps xmm8, xmm10; ...|0.9*G1|0.9*G0|
; 			cvttps2dq xmm3, xmm3  ;(cvttps2dq convierte con truncamiento, cvtps2dq convierte sin truncamiento)
; 			cvttps2dq xmm4, xmm4
; 			cvttps2dq xmm8, xmm8

; 			paddusb xmm3, xmm2; funciona porque tanto b/2 como 0.9*componente estan en el primer byte
; 			paddusb xmm4, xmm2
; 			paddusb xmm8, xmm2
; 			pslld xmm4, 16
; 			pslld xmm8, 8

; 			por xmm3, xmm4
; 			por xmm3, xmm8
; 			por xmm3, xmm11

; 			movq [rsi], xmm3; carga en memoria los pixeles modificados
; 			add rdi, 8
; 			add rsi, 8
; 			add r13, 2; i+=2
; 			dec rcx
; 			cmp rcx, 0
; 			jne .cicloColumnas
; 			mov r13, 0; resetea i cuando comienza con la siguiente fila
; 			pop rdx
; 			pop rcx
; 			dec rcx
; 			inc r12; j++
; 			cmp rcx, 0
; 			jne .cicloFilas
; 	add rsp, 8
; 	pop rbx
; 	pop r15
; 	pop r14
; 	pop r13
; 	pop r12
; 	pop rbp
; 	ret