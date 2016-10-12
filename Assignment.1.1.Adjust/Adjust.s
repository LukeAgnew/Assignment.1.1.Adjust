	AREA	Adjust, CODE, READONLY
	IMPORT	main
	IMPORT	getPicAddr
	IMPORT	putPic
	IMPORT	getPicWidth
	IMPORT	getPicHeight
	EXPORT	start
	PRESERVE8

start
	BL	getPicAddr					; load the start address of the image in R4
	MOV	R4, R0
	BL	getPicHeight				; load the height of the image (rows) in R5
	MOV	R5, R0
	BL	getPicWidth					; load the width of the image (columns) in R6
	MOV	R6, R0
	
	LDR R7,= 30						; Alpha = 30
	LDR R8,= 35						; Beta = 
	
	MOV R0, R4						; starting address parameter
	MOV R1, R7						; value of Alpha parameter
	MOV R2, R8						; value of Beta parameter
	MOV R3, R5						; image height parameter
	STR R6, [SP, #-4]!				; image width parameter
	
	BL adjustImage					; invoke adjustImage(address, Alpha, Beta, height, width)

	ADD SP,SP,#4					; pop image width parameter off the stack
	
	BL	putPic						; re-display the updated image

stop	B	stop


; adjustImage subroutine
; Adjusts the brightness and contrast of an image according
; to the values of Alpha and Beta that are passed to the subroutine
; parameters	R0: starting address of the array/image
;				R1: value of Alpha
;				R2: value of Beta
;				R3: the height of the image
;			   [SP]:the width of the image

adjustImage
	STMFD SP!, {R4-R10, lr}			; save registers
	
	LDR R4, [SP, #0+32]				; load the image width parameter
	
	LDR R10,=16						; constant 16
	
	LDR R5,=0					
fori								
	CMP R5,R3						; for (int i=0; i<height; i++)
	BHS endfori						; {

	LDR R6,=0	
forj
	CMP R6,R4						; for (int j=0; j<width; j++)
	BHS endforj						; {

	STMFD SP!, {R0-R3}				; save address, Alpha, Beta and height to the system stack 
	
	MOV R1, R5						; index i parameter
	MOV R2, R6						; index j parameter
	MOV R3, R4						; width parameter

	BL getPixelR					; invoke getPixelR(address, i, j, width)
	MOV R7, R0						; Rij value
	LDMFD SP!, {R0-R3}				; restore address, Alpha, Beta and height from the system stack
	
	STMFD SP!, {R0-R3}				; save address, Alpha, Beta and height to the system stack
	MOV R1, R5						; index i parameter
	MOV R2, R6						; index j parameter
	MOV R3, R4						; width parameter

	BL getPixelG					; invoke getPixelG(address, i, j, width)
	MOV R8, R0						; Gij value
	LDMFD SP!, {R0-R3}				; restore address, Alpha, Beta and height from the system stack
	
	STMFD SP!, {R0-R3}				; save address, Alpha, Beta and height to the system stack
	MOV R1, R5						; index i parameter
	MOV R2, R6						; index j parameter
	MOV R3, R4						; width parameter

	BL getPixelB					; invoke getPixelB(address, i, j, width)
	MOV R9, R0						; Bij value	
	LDMFD SP!, {R0-R3}				; restore Alpha, Beta and height from the system stack 
	
	STMFD SP!, {R0-R1}				; save address and Alpha to the system stack
	
	MUL R7,R1,R7					; Rij × Alpha
	
	MOV R0,R7						; dividend parameter = Rij × Alpha
	MOV R1,R10						; divisor parameter = 16
	
	BL divide						; invoke divide(dividend, divisor)
	MOV R7,R0						; R'ij = (Rij× Alpha)/16
	LDMFD SP!, {R0-R1}				; restore address and Alpha from the system stack
	
	STMFD SP!, {R0-R1}				; save address and Alpha to the system stack
	
	MUL R8,R1,R8					; Gij × Alpha
	
	MOV R0, R8						; dividend parameter = Gij × Alpha
	MOV R1,R10						; divisor parameter = 16
	
	BL divide						; invoke divide(dividend, divisor)
	MOV R8,R0						; G'ij = (Gij× Alpha)/16
	LDMFD SP!, {R0-R1}				; restore address and Alpha from the system stack
	
	STMFD SP!, {R0-R1}				; save address and Alpha to the system stack
	
	MUL R9,R1,R9					; Bij × Alpha
	
	MOV R0, R9						; dividend parameter = Bij × Alpha
	MOV R1, R10						; divisor parameter = 16

	BL divide						; invoke divide(dividend, divisor)
	MOV R9,R0						; B'ij = (Bij× Alpha)/16
	LDMFD SP!, {R0-R1}				; restore address and Alpha from the system stack
	
	ADD R7,R7,R2					; R'ij = R'ij + Beta
	ADD R8,R8,R2					; G'ij = G'ij + Beta
	ADD R9,R9,R2					; B'ij = B'ij + Beta
	
	STMFD SP!, {R0-R2}					; save address to the system stack
	
	MOV R0,R7						; redComponent parameter = R'ij
	MOV R1,R8						; greenComponent parameter = G'ij
	MOV R2,R9						; blueComponent parameter = B'ij
	
	BL checkVals					; invoke checkVals(redComponent, greenComponent, blueComponent)
	
	MOV R7,R0						; redComponent return value
	MOV R8,R1						; greenComponent return value
	MOV R9,R2						; blueComponent return value
	
	LDMFD SP!, {R0-R2}					; restore address from the system stack
	
	STMFD SP!, {R0-R3}				; save address, Alpha, Beta and height to the system stack
	
	MOV R1,R5						; i parameter = i
	MOV R2,R6						; j parameter = j
	MOV R3,R4						; width parameter = width
	STR R7, [SP, #-4]!				; store R'ij to the system stack
	
	BL setPixelR					; invoke setPixelR(address, i, j, width, value)
	ADD SP,SP,#4					; pop parameter off the stack
	
	MOV R1,R5						; i parameter = i
	MOV R2,R6						; j parameter = j
	MOV R3,R4						; width parameter = width
	STR R8, [SP, #-4]!				; store G'ij to the system stack
	
	BL setPixelG					; invoke setPixelG(address, i, j, width, value)
	ADD SP,SP,#4					; pop parameter off the stack
	
	MOV R1,R5						; i parameter = i
	MOV R2,R6						; j parameter = j
	MOV R3,R4						; width parameter = width
	STR R9, [SP, #-4]!				; store B'ij to the system stack
	
	BL setPixelB					; invoke setPixelB(address, i, j, width, value)
	ADD SP,SP,#4					; pop parameter off the stack
	
	LDMFD SP!, {R0-R3}				; restore address, Alpha, Beta and height from the system stack
	
	ADD R6,R6,#1
	B forj							; }
endforj

	ADD R5,R5,#1
	B fori							; }
endfori
	
	LDMFD SP!, {R4-R10, pc}			; restore registers

	
; getPixelR subroutine
; Retrieves the Red color component of a specified pixel
; from a two-dimensional array of pixels.
; parameters	R0: starting address of the array
;				R1: index i of the pixel
;				R2: index j of the pixel
;				R3: width of the array

getPixelR
	STMFD SP!, {R4, lr}				; save registers

	MUL R1,R3,R1					; row * rowSize						
	ADD R1,R1,R2					; row*rowSize + column 
	
	LDR R0, [R0, R1, LSL #2]		; pixel = Memory.Word[address + (index * 4)]
	MOV R0,R0, LSR #16				; redComponent = pixel shifted right by 16 bits

	LDMFD SP!, {R4, PC}				; restore registers
	
	
; getPixelG subroutine
; Retrieves the Green color component of a specified pixel
; from a two-dimensional array of pixels.
; parameters	R0: starting address of the array
;				R1: index i of the pixel
;				R2: index j of the pixel
;				R3: width of the array
	
getPixelG
	STMFD SP!, {R4, lr}				; save registers

	MUL R1,R3,R1					; row * rowSize						
	ADD R1,R1,R2					; row*rowSize + column 
	
	LDR R0, [R0, R1, LSL #2]		; pixel = Memory.Word[address + (index * 4)]
	MOV R0,R0,LSR #8 				; greenComponent = pixel shifted right by 8 bits and
	LDR R4,=0xFFFFFF00				; combined with a mask to clear the redComponent value
	BIC R0,R0,R4
	
	LDMFD SP!, {R4,PC}				; restore registers
	
	
; getPixelB subroutine
; Retrieves the Blue color component of a specified pixel
; from a two-dimensional array of pixels.
; parameters	R0: starting address of the array
;				R1: index i of the pixel
;				R2: index j of the pixel
;				R3: width of the array
	
getPixelB
	STMFD SP!, {R4, lr}				; save registers

	MUL R1,R3,R1					; row * rowSize						
	ADD R1,R1,R2					; row*rowSize + column 
	
	LDR R0, [R0, R1, LSL #2]		; pixel = Memory.Word[address + (index * 4)]
	LDR R4,=0xFFFFFF00				; blueComponent = pixel combined with a mask to clear
	BIC R0,R0,R4					; the redComponent and greenComponent values
	
	LDMFD SP!, {R4,PC}				; restore registers
	
	
; divide subroutine
; Takes a number (the dividend) and divides it by another number (the divisor) and
; then returns the result (the quotient)
; parameters   R0: The dividend, i.e. the number to be divided
;			   R1: The divisor, i.e. the number to divide into the dividend
; return value R0: quotient
	
divide
	STMFD sp!, {R4, lr}				; save registers
	MOV R4,#0						; quotient = 0
wh	CMP R0, R1						; while (dividend > divisor)
	BLO endwh						; {
	SUB R0, R0, R1					; dividend = dividend - divisor
	ADD R4,R4,#1					; quotient = quotient + 1
	B wh							; }
endwh
	MOV R0,R4						; return value = quotient
	LDMFD sp!, {R4, pc}				; restore registers
	
	
; checkVals subroutine
; Checks the value of the passed parameter (an rgb color component) to see whether
; it is above 255 or below 0, in which case it sets the value to the limit
; parameters	R0:	the color component
; return value	R0: the color component

checkVals
	STMFD SP!, {lr}

checkRed
	CMP R0,#255						; if (redComponent > 255)
	BHI upperLimitRed				; { branch to upperLimitRed }
			
	CMP R0,#0						; if (redComponent < 0)
	BLO lowerLimitRed				; { branch to lowerLimitRed }

checkGreen
	CMP R1,#255						; if (greenComponent > 255)
	BHI upperLimitGreen				; { branch to upperLimitGreen }

	CMP R1,#0						; if (greenComponent < 0)
	BLO lowerLimitGreen				; { branch to lowerLimitGreen }

checkBlue
	CMP R2,#255						; if (blueComponent > 255)
	BHI upperLimitBlue				; { branch to upperLimitGreen }

	CMP R2,#0						; if (blueComponent < 0)
	BLO lowerLimitBlue				; { branch to lowerLimitBlue }

endcheckVals	
	LDMFD sp!, {pc}
	
upperLimitRed
	MOV R0,#255						; redComponent = 255
	B checkGreen
		
lowerLimitRed
	MOV R0,#0						; redComponent = 0
	B checkGreen
	
upperLimitGreen
	MOV R1,#255						; greenComponent = 255
	B checkBlue

lowerLimitGreen
	MOV R1,#0						; greenComponent = 0
	B checkBlue

upperLimitBlue
	MOV R2,#255						; blueComponent = 255
	B endcheckVals

lowerLimitBlue
	MOV R2,#0						; blueComponent = 0
	B endcheckVals
	

; setPixelR subroutine
; Sets the Red color component of a specified pixel in a
; two-dimensional array of pixels.
; parameters	R0:	starting address of the array
;				R1: index i of pixel
;				R2: index j of pixel
;				R3: width of the array
;			   [SP]: value added to the stack
setPixelR
	STMFD SP!, {R4-R5, lr}			; save registers

	MUL R1,R3,R1					; row * rowSize
	ADD R1,R1,R2					; row*rowSize + column
	
	LDR R4,[R0, R1, LSL #2]			; pixel = Memory.Word[address + (index*4)]

	BIC R4,R4,#0x00FF0000			; clear the pixel's current redComponent value
	
	LDR R5,[SP, #0 + 12]			; load the redComponent value from the stack
	MOV R5,R5,LSL #16				; shift redComponent value left by 16 bits

	ADD R4,R4,R5					; add this redComponent value to the pixel
	
	STR R4, [R0, R1, LSL #2]		; Memory.Word[address + (index*4)] = pixel
	
	LDMFD SP!, {R4-R5, pc}			; restore registers
	

; setPixelG subroutine
; Sets the Green color component of a specified pixel in a
; two-dimensional array of pixels.
; parameters	R0:	starting address of the array
;				R1: index i of pixel
;				R2: index j of pixel
;				R3: width of the array
;			   [SP]: value added to the stack
setPixelG
	STMFD SP!, {R4-R5, lr}			; save registers

	MUL R1,R3,R1					; row * rowSize
	ADD R1,R1,R2					; row*rowSize + column
	
	LDR R4,[R0, R1, LSL #2]			; pixel = Memory.Word[address + (index*4)]

	BIC R4,R4,#0x0000FF00			; clear the pixel's current greenComponent value
	
	LDR R5,[SP, #0 + 12]			; load the greenComponent value from the stack	
	MOV R5,R5,LSL #8				; shift the greenComponent value left by 8 bits

	ADD R4,R4,R5					; add this greenComponent value to the pixel
	
	STR R4, [R0, R1, LSL #2]		; Memory.Word[address + (index*4)] = pixel
	
	LDMFD SP!, {R4-R5, pc}			; restore registers


; setPixelB subroutine
; Sets the Blue color component of a specified pixel in a
; two-dimensional array of pixels.
; parameters	R0:	starting address of the array
;				R1: index i of pixel
;				R2: index j of pixel
;				R3: width of the array
;			   [SP]: value added to the stack
setPixelB
	STMFD SP!, {R4-R5, lr}			; save registers

	MUL R1,R3,R1					; row * rowSize
	ADD R1,R1,R2					; row*rowSize + column
	
	LDR R4,[R0, R1, LSL #2]			; pixel = Memory.Word[address + (index*4)]

	BIC R4,R4,#0x000000FF			; clear the pixel's current blueComponent value
	
	LDR R5,[SP, #0 + 12]			; load the blueComponent value from the system stack
	
	ADD R4,R4,R5					; add this blueComponent value to the pixel
	
	STR R4, [R0, R1, LSL #2]		; Memory.Word[address + (address*4)] = pixel
	
	LDMFD SP!, {R4-R5, pc}			; restore registers

	END	