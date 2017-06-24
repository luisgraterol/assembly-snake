.data
		inicio:  .word 0x10010000		# Inicio del bitmap
		esquina: .word 0x10010084		# Esquina superior izquierda
		te: 	 .word 0xffff0004		# Contiene el ultimo caracter en ser tecleado
		tc: 	 .word 0xffff0000		# Se prende en 1 cuando se va a mandar el caracter tecleado
			 .space 1048576			# 512 x 512 x 4 (bytes)


.macro	tablero($inicio,$desp,$linea)
		move $t1,$inicio			# El color sigue guardado en $s4
		li $t2, 0				# Contador 1
		li $t3, 2				# Contador 2 (hacia atras)
		
	loop:	li $t2, 0				# Vuelves a poner en 0 el contador 1
		subi $t3, $t3, 1			# Le restas 1 al contador 2
			
	loop2:  sw $s4,0($t1)				# Pintas la direccion en $t1
		add $t1, $t1, $desp			# Le sumas el desplazamiento a $t1
		addi $t2, $t2, 1			# Le sumas 1 al contador 1
		blt $t2, 30, loop2
			
		lw $t1, esquina
		add $t1, $t1, $linea			# Bajas la direccion a pintar una linea?
		bnez $t3, loop
.end_macro	

.macro fruta()
	random:
		li $v0,42
		li $a1,3564
		syscall
		
		addi $a0,$a0,132
		move $t7,$a0
		li $t6,128
		div $t7,$t6
		mfhi $t6
		ble $t6,8,random
		bge $t6,120,random
		li $t6,4
		div $t7,$t6 
		mfhi $t6
		bnez $t6,random
		add $t7, $t7, $s0
		lw $t6,0($t7)
		bne $t6,$zero,random
	
		sw $s5,0($t7)
.end_macro

.macro revisar($posComer)
		beq $posComer,$s3,fin
		beq $posComer,$s4,fin
		beq $posComer,$s6,fin
		#beq $posComer,$s5,comerFruta	
.end_macro		 
			 			 
			 
.text
		li $s3,0x0066cc	 # blue
		li $s4,0x00ff00	 # green	
		li $s5,0xcc6611	 # orange
		li $s6,0xcccccc  # grey
		
		# Tablero
		lw $s0, esquina				# Guardamos en $s0 la direccion de la esquina del tablero
		li $s1, 4				# Desplazamiento para mover a la derecha
		li $s2, 3712				# Nro. de linea
		tablero($s0,$s1,$s2)			# Pintamos los bordes horizontales
	
		li $s1, 128				# Desplazamiento para mover hacia abajo
		li $s2, 116				# Nro. de linea
		tablero($s0,$s1,$s2)			# Pintamos los bordes verticales
	
		fruta()					# Se genera una fruta random
		
		# Snake
		li $t2,0				# $t2 sera un contador
		la $t1, 1848($s0)			# Guardamos la posicion de la esquina en $t1
		
mover:
		sw $s3,0($t1)				# Pintar (empieza en el medio)
		li $v0,30
		syscall					# Syscall 30: Tiempo
			
		move $s1,$a0				# Guardamos el tiempo en $s1
		addi $s1,$s1,1000			# Le sumamos un segundo a $s1	
			
tiempo:
		la $t5, 0xffff0000
		lw $t5, 0($t5)
		bnez $t5,teclado
			
		li $v0,30
		syscall					# Syscall 30: Tiempo
			
		blt $a0,$s1,tiempo 
			
direccion:
		sw $zero,0($t1)				# Borrar				

		beq $t2,1,derecha
		beq $t2,2,izquierda
		beq $t2,3,abajo
		beq $t2,4,arriba
		
		b continuar
		
	derecha:				# if de direccion
		lw $t4,4($t1)
		revisar($t4)
		addi $t1,$t1,4 
		li $t3,1
		b continuar
	izquierda:
		lw $t4,-4($t1)
		revisar($t4)
		addi $t1,$t1,-4
		li $t3,2
		b continuar
	abajo:
		lw $t4,128($t1)
		revisar($t4)
		addi $t1,$t1,128
		li $t3,3
		b continuar
	arriba:
		lw $t4,-128($t1)
		revisar($t4)
		addi $t1,$t1,-128
		li $t3,4
		b continuar
		
	continuar:
		bne $t2,5,mover			# Para terminar o perder poner $t2 en 5
		b fin
	
		
			
teclado:
		la $s2, 0xffff0004
		lw $s2, 0($s2)
		
		li $t2,1
		beq $s2,100,direccion	# 100 es D, derecha
		li $t2,2
		beq $s2,97,direccion	# 97 es A, izquierda
		li $t2,3
		beq $s2,115,direccion	# 115 es S, abajo
		li $t2,4
		beq $s2,119,direccion	# 119 es W, arriba
		
		move $t2,$t3		# ultima direccion escrita
		b tiempo

fin:   
	li $v0, 10
	syscall
