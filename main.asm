#
#			PROYECTO 1
#	Version 0.3
#	Organizacion del Computador
#	Autores: Santiago Lossada
#			 Luis Graterol
#	
#			LEYENDA
#	$s0 = Vidas
#	$s1 = Tiempo
#	$s2 = Puntos Acumulados
#	$s3 = Color
#	$s4 = Longitud de la Culebra
#	$s5 = Multiplo de Puntuacion
#	$s6 = Nro. de ms entre cada movimiento (Velocidad)
#	$s7 = Contador del tiempo
#
#	$t0 = Posicion a pintar (Cabeza)
#	$t1 = Ultimo dato ingresado
#	$t2 = Direccion del proximo movimiento
#	$t3 = Direccion del ultimo movimiento
#	$t4 = Posicion delante de $t1
#	$t5 = Multiples usos
#	$t6 = Direccion de la esquina del tablero
#	$t7 = Multiples usos
#	$t8 = Multiples usos
#	$t9 = Cola
#
.data
		# Bitmap
		inicio:  .word 0x10010000		# Inicio del bitmap
		esquina: .word 0x10010084		# Esquina superior izquierda
			 .space 1048576			# 512 x 512 x 4 (bytes)
		
		# Colores
		snake: 	 .word 0x0066cc	 		# Azul
		pared: 	 .word 0x69e569	 		# Verde	
		fruta: 	 .word 0xcc6611	 		# Anaranjado
		roca:    .word 0xcccccc  		# Gris
		
		# Strings
		seguir:  		.asciiz "Presione cualquier tecla de direccion para continuar: "
		puntaje: 		.asciiz "El juego a terminado. Su puntaje final fue de: "
		gracias: 		.asciiz " puntos\nGracias por jugar!\n"
		volver_jugar: 	.asciiz "Desea volver a jugar?\nIntroduzca '1' para volver a jugar:\n"
		backl: 			.asciiz "\n"
		
	    # Macro: Pinta el tablero
.macro  tablero($desp,$linea)
		lw $s3,pared					# Guardamos el color de la pared
		lw $t1,esquina				
		li $t2, 0						# Contador 1
		li $t3, 2						# Contador 2 (hacia atras)
		
	loop:	li $t2, 0						# Vuelves a poner en 0 el contador 1
		subi $t3, $t3, 1				# Le restas 1 al contador 2
			
	loop2:  sw $s3,0($t1)					# Pintas la direccion en $t1
		add $t1, $t1, $desp				# Le sumas el desplazamiento a $t1
		addi $t2, $t2, 1				# Le sumas 1 al contador 1
		blt $t2, 30, loop2
			
		lw $t1, esquina
		add $t1, $t1, $linea			# Bajas la direccion a pintar una linea?
		bnez $t3, loop
.end_macro	

	   	# Macro: Pinta una fruta o roca en un lugar aleatorio del tablero
.macro 	generarObjeto($color)
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
		lw $t8,esquina
		add $t7, $t7, $t8
		lw $t6,0($t7)
		bne $t6,$zero,random
	
		sw $color,0($t7)
.end_macro

.macro generacion


.end_macro

	   	# Macro: Revisa el cuadro a comer
.macro 	revisar($posComer)
		lw $s3, pared
		beq $posComer,$s3,quitarvida
		lw $s3, roca
		beq $posComer,$s3,quitarvida
		li $s3, 0
		beq $posComer, $s3, norevisar
		lw $s3, snake
		li $t7, 0x00ffffff
		and $posComer, $posComer, $t7
		beq $posComer,$s3,quitarvida
		lw $s3, fruta
		bne $posComer,$s3,norevisar					# Si la posicion a comer no tiene el color de la fruta,
		
		addi $s4,$s4,1									
											# entonces se salta al final de la macro y no se revisa
		mul $t7, $s5, 10							# Los puntos a sumar ($t7) se obtienen multiplicando el multiplo de puntuacion ($s5) * 10
		add $s2, $s2, $t7							# En $s2 se acumulan los puntos ganados en la partida actual
		generarObjeto($s3)							# En $s3 esta todavia el color de la fruta
		
	norevisar:
.end_macro		 	

.macro  limpiarTablero()
		lw $t6, esquina
		li $t8, 0
		addi $t6,$t6,-4
	loop3:	addi $t6,$t6,4
		addi $t8, $t8, 1
		lw $t7, 0($t6)
		
		lw $s3, snake
		beq $t7, $s3, loop3
		li $t5, 0x00ffffff
		and $t7, $t7, $t5
		beq $t7,$s3,loop3
		
		lw $s3, pared
		beq $t7, $s3, loop3
		sw $zero,0($t6)								# Borrar
		ble $t8,1024, loop3
.end_macro

.macro  limpiarTablero2()
		lw $t6, esquina
		li $t8, 0
		addi $t6,$t6,-4
	loop3:	addi $t6,$t6,4
		addi $t8, $t8, 1
		lw $t7, 0($t6)
		lw $s3, pared
		beq $t7, $s3, loop3
		sw $zero,0($t6)								# Borrar
		ble $t8,1024, loop3
.end_macro

.macro  borrarTablero()
		lw $t6, esquina
		li $t7, 0
		addi $t6,$t6,-4
	loop3:	addi $t6,$t6,4
		addi $t7, $t7, 1
		sw $zero,0($t6)								# Borrar
		ble $t7,1024, loop3
.end_macro

.macro guardarDirec($direc)
		move $t7,$direc
		sll $t7,$t7,24
		lw $t8,0($t0)
		or $t8,$t8,$t7
		sw $t8,0($t0)
.end_macro


.text		
volver:
		# Tablero
		# lw $t6, esquina					# Guardamos en $t6 la direccion de la esquina del tablero
		li $s1, 4							# Desplazamiento para mover a la derecha
		li $s2, 3712						# Nro. de linea
		tablero($s1,$s2)					# Pintamos los bordes horizontales
	
		li $s1, 128							# Desplazamiento para mover hacia abajo
		li $s2, 116							# Nro. de linea
		tablero($s1,$s2)					# Pintamos los bordes verticales
		
		
		# Snake
		li $s7, 0
		li $s2, 0							# Se inicializa el puntaje en 0
		li $s0, 3							# Se inicializan las vidas
		li $s5, 10							# 				el multiplo de puntuacion en 1
		li $s6, 1000							#				la velocidad en 1000 (ms)
		li $s7, 0							# 				el contador del tiempo en 0
		li $t2, 10							# $t2 sera un contador
		li $t3,10
		li $s4, 2
		lw $s3, fruta
		generarObjeto($s3)					# Generamos la primera fruta
		lw $s3, roca
		generarObjeto($s3)
		lw $t6, esquina						# Guardamos en $t6 la direccion de la esquina del tablero
		la $t0, 1848($t6)					# Guardamos la posicion central en $t0
		move $t9, $t0						# La cola empieza en el mismo lugar que la cabeza
		
mover:
		lw $s3, snake
		sw $s3,0($t0)							# Pintar (empieza en el medio)
		
		li $v0,30
		syscall								# Syscall 30: Tiempo
		
		move $s1,$a0							# Guardamos el tiempo en $s1
		add $s1,$s1,$s6							# Le sumamos el tiempo entre cada movimiento a $s1

		bnez $s7, revisar

iniciarTiempo:
		move $s7, $a0
		addi $s7, $s7, 10000

revisar:	blt $a0, $s7, tiempo		
		
incrementar:	
		mul $t7, $s5, 10							# Los puntos a sumar ($t7) se obtienen multiplicando el multiplo de puntuacion ($s5) * 10
		add $s2, $s2, $t7
		li $s7,0								# Vuelves a poner en 0 el contador del tiempo
		limpiarTablero()
		lw $s3, fruta
		generarObjeto($s3)
		lw $s3, roca
		generarObjeto($s3)
		
		addi $s5, $s5, 2
		
		ble $s6, 200, tiempo					# 200 ms es la maxima velocidad
		addi $s6, $s6, -200						# Se disminuye el tiempo en 200 ms cada 10 segundos
			
tiempo:
		la $t1, 0xffff0000
		lw $t1, 0($t1)
		bnez $t1,teclado 
			
		li $v0,30
		syscall							# Syscall 30: Tiempo
			
		blt $a0,$s1,tiempo 
			
direccion:
		# sw $zero,0($t0)						# Borrar				
		add $t7,$t3,$t2
		beq $t7,3,mantener
		beq $t7,7,mantener
		b nomantener
	mantener:
		move $t2,$t3
	nomantener:
		beq $t2,1,derecha
		beq $t2,2,izquierda
		beq $t2,3,abajo
		beq $t2,4,arriba
		
		b colacha
		
	derecha:			# If de direccion
		lw $t4,4($t0)
		revisar($t4)
		guardarDirec($t2)
		addi $t0,$t0,4
		li $t3,1
		b continuar
	izquierda:
		lw $t4,-4($t0)
		revisar($t4)
		guardarDirec($t2)
		addi $t0,$t0,-4
		li $t3,2
		b continuar
	abajo:
		lw $t4,128($t0)
		revisar($t4)
		guardarDirec($t2)
		addi $t0,$t0,128
		li $t3,3
		b continuar
	arriba:
		lw $t4,-128($t0)
		revisar($t4)
		guardarDirec($t2)
		addi $t0,$t0,-128
		li $t3,4
		
	continuar:
		bgtz $s4,nocolacha

		lw $t7,0($t9)
		sw $zero,0($t9)
		srl $t7,$t7,24
		beq $t7,1,colaD
		beq $t7,2,colaI
		beq $t7,3,colaAb
		beq $t7,4,colaAr
		colaD:
			addi $t9,$t9,4
			b colacha
		colaI:
			addi $t9,$t9,-4
			b colacha
		colaAb:
			addi $t9,$t9,128
			b colacha
		colaAr:
			addi $t9,$t9,-128
			b colacha
	nocolacha:
		addi $s4,$s4,-1
	colacha:
		bne $t2,5,mover		# Para terminar o perder poner $t2 en 5
		b fin
	
		
			
teclado:
		la $t1, 0xffff0004
		lw $t1, 0($t1)
		li $t2,1
		beq $t1,100,direccion		# 100 es D, derecha
		li $t2,2
		beq $t1,97,direccion		# 97 es A, izquierda
		li $t2,3
		beq $t1,115,direccion		# 115 es S, abajo
		li $t2,4
		beq $t1,119,direccion		# 119 es W, arriba
		
		beq $t1,112,pausar			# 112 es P, pausa
		
		move $t2,$t3				# Ultima direccion escrita
		b tiempo

pausar:
		li $v0, 4
		la $a0, seguir
		syscall
		
		li $v0, 12
		syscall
		
		sw $zero,0($t0)				# Borrar
		
		li $t2,1
		beq $v0, 100, derecha		# 100 es D, derecha
		li $t2,2
		beq $v0, 97, izquierda		# 97 es A, izquierda
		li $t2,3
		beq $v0, 115, abajo			# 115 es S, abajo
		li $t2,4
		beq $v0, 119, arriba		# 119 es W, arriba
		
		move $t2,$t3				# Ultima direccion escrita
		b tiempo



quitarvida:
		li $s7, 0
		lw $t6,esquina
		la $t0, 1848($t6)
		la $t9, 1848($t6)
		li $s4, 2
		li $t2, 10
		li $t3, 10
		li $s5, 10
		li $s6, 1000
		addi $s0,$s0,-1
		beqz $s0,terminar
		limpiarTablero2()
		lw $s3, fruta
		generarObjeto($s3)
		lw $s3, roca
		generarObjeto($s3)
		
		bnez $s0,mover

terminar:
		li $v0, 4
		la $a0, puntaje
		syscall
		
		li $v0, 1
		move $a0, $s2
		syscall
		
		li $v0, 4
		la $a0, gracias
		syscall
		
		la $a0, volver_jugar
		syscall
		
		li $v0,5
		syscall
		
		borrarTablero()
		li $t6,1
		beq $v0,$t6,volver
		
fin:   
	li $v0, 10
	syscall
