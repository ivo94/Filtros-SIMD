section .rodata

align 16

mask_blue:  db 0x00,0xFF,0xFF,0xFF,0x04,0xFF,0xFF,0xFF,0x08,0xFF,0xFF,0xFF,0x0C,0xFF,0xFF,0xFF

mask_green: db 0x01,0xFF,0xFF,0xFF,0x05,0xFF,0xFF,0xFF,0x09,0xFF,0xFF,0xFF,0x0D,0xFF,0xFF,0xFF

mask_red:   db 0x02,0xFF,0xFF,0xFF,0x06,0xFF,0xFF,0xFF,0x0A,0xFF,0xFF,0xFF,0x0E,0xFF,0xFF,0xFF

mask_first_byte: db 0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00

copy_first_dw: db 0x00,0x01,0x02,0x03,0x00,0x01,0x02,0x03,0x00,0x01,0x02,0x03,0x00,0x01,0x02,0x03

saturate_transp: db 0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF


section .text

extern ReforzarBrillo_c
global ReforzarBrillo_asm

ReforzarBrillo_asm:
;Parametros
;rdi = src
;rsi = dst
;edx = width
;ecx = height
;r8d = src_row_size
;r9d = dst_row_size
;[rbp + 16] = umbralSup
;[rbp + 24] = umbralInf
;[rbp + 32] = brilloSup
;[rbp + 40] = brilloInf

	push rbp
	mov rbp, rsp

	push r12
	push r13
	push r14
	push r15
	mov r12, rdi; r12 = src
	mov r13, rsi; r13 = dst
	mov r14d, [rbp + 16]
	mov r15d, [rbp + 32]
	mov r8d, [rbp + 24]
	mov r9d, [rbp + 40]


	;si proceso de a 4 pixeles el algoritmo se ejecuta ( (width/4) * height) veces
	mov r10, rdx
	shr r10, 2; r10 = width/4
	mov rax, r10; rax = width/4
	mul rcx; rax = (width/4) * height
	mov rcx, rax; rcx = (width/4) * height

	movdqa xmm10, [mask_blue]
	movdqa xmm11, [mask_green]
	movdqa xmm12, [mask_red]
	movdqa xmm13, [mask_first_byte]
	movdqa xmm14, [copy_first_dw]
	movdqa xmm15, [saturate_transp]

	.mainLoop:
		cmp rcx, 0
		je .end
		dec rcx

		movdqa xmm0, [r12]; xmm0 = [A3 R3 G3 B3 A2 R2 G2 B2 A1 R1 G1 B1 A0 R0 G0 B0]
		movdqa xmm1, xmm0;  xmm1 = [A3 R3 G3 B3 A2 R2 G2 B2 A1 R1 G1 B1 A0 R0 G0 B0]
		movdqa xmm2, xmm0;  xmm2 = [A3 R3 G3 B3 A2 R2 G2 B2 A1 R1 G1 B1 A0 R0 G0 B0]
		movdqa xmm3, xmm0;  xmm3 = [A3 R3 G3 B3 A2 R2 G2 B2 A1 R1 G1 B1 A0 R0 G0 B0]

		; pshufb xmm1, xmm10;  xmm1 = [0 0 0 B3 0 0 0 B2 0 0 0 B1 0 0 0 B0]
		; pshufb xmm2, xmm11; xmm2 = [0 0 0 G3 0 0 0 G2 0 0 0 G1 0 0 0 G0]
		; pshufb xmm3, xmm12;   xmm3 = [0 0 0 R3 0 0 0 R2 0 0 0 R1 0 0 0 R0]

		pshufb xmm1, [mask_blue]
		pshufb xmm2, [mask_green]
		pshufb xmm3, [mask_red]

		movdqa xmm4, xmm1
		paddd xmm4, xmm2
		paddd xmm4, xmm2
		paddd xmm4, xmm3; xmm4 = [B3+2*G3+R3 B2+2*G2+R2 B1+2*G1+R1 B0+2*G0+R0]

		psrld xmm4, 2
		;pand xmm4, xmm13; xmm4 = [b3 b2 b1 b0]
		pand xmm4, [mask_first_byte]

		movdqa xmm5, xmm4; xmm5 = [b3 b2 b1 b0]

		movd xmm6, r14d; xmm6 = [0 0 0 umbralSup]
		pshufb xmm6, xmm14; xmm6 = [umbralSup umbralSup umbralSup umbralSup]

		movd xmm7, r15d; xmm7 = [0 0 0 brilloSup]
		;pshufb xmm7, xmm14; xmm7 = [brilloSup brilloSup brilloSup brilloSup]
		pshufb xmm7, [copy_first_dw]


		pcmpgtd xmm5, xmm6; compara dword contra dword, todos unos si b > umbralSup todos ceros si no
		pand xmm7, xmm5; brilloSup en las dwords donde b > umbralSup

		paddusb xmm1, xmm7
		paddusb xmm2, xmm7
		paddusb xmm3, xmm7

		movd xmm8, r8d
		;pshufb xmm8, xmm14; xmm8 = [umbralInf umbralInf umbralInf umbralInf]
		pshufb xmm8, [copy_first_dw]
		movd xmm9, r9d
		;pshufb xmm9, xmm14; xmm9 = [brilloInf brilloInf brilloInf brilloInf]
		pshufb xmm9, [copy_first_dw]


		movdqa xmm5, xmm4; xmm5 = [b3 b2 b1 b0]
		pcmpgtd xmm8, xmm5
		pand xmm9, xmm8; brillosInf en las dwords donde b < umbralSup

		psubusb xmm1, xmm9
		psubusb xmm2, xmm9
		psubusb xmm3, xmm9

		;reacomodo
		pslld xmm2, 8
		pslld xmm3, 16

		por xmm1, xmm2
		por xmm1, xmm3

		;saturo transparencia
		;por xmm1, xmm15
		por xmm1, [saturate_transp]

		movdqa [r13], xmm1; carga en memoria

		add r12, 16; avanza 4 pixeles imagen fuente
		add r13, 16; avanza 4 pixeles imagen destino
		jmp .mainLoop

	.end:
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbp
		ret