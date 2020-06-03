
;author: Ashraf Habromman
;Id: 11821493

.model small

.stack 200H
.data
						;note that code work using the upper numbers not numbers at the right side						

						;mount c: c:\masm\bin 

operand1 DB 20 dup(?) 				;it will requires 5 byte at most ; highest value = 65535 . 
operand2 DB 20 dup(?) 
operation DB ?

operandBinary1 DW ? 
operandBinary2 DW ? 

result DD 0

messege DB "Im here $"



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code


mov ax,@data
mov ds,ax
mov si, offset operand1 
start:

ReadChar: 			
	PUSH DX
        PUSH AX					;Reading  char from user . 
 	MOV  AH, 1
	INT  21H

	cmp al,20h				; 20h = space 
	je ReadChar 				; ignore space if user enter it between any char  

	cmp al,'+'				;sum sign
	je storOperation			;jump to storOperation label if user enter one of the signs 
	cmp al,'-'				;sub sign
	je storOperation
	cmp al,'*'				;multiplication sign
	je storOperation
	cmp al,'/'				;division sign
	je storOperation
	cmp al,'U'				;division with the result rounded up sign 
	je storOperation
	cmp al,'D'				;division with the result rounded down sign 
	je storOperation
	cmp al,'^'				;power sign 
	je storOperation

	
	cmp al,'='
	je stopReading
	
	cmp al ,'0'				; ignore any thing else 
	jb ReadChar
	cmp al ,'9'
	ja ReadChar

	sub al, 30h				;subtracte 30 from value '0'= 30h ; 30h-30h = 0 
	mov [si], al 				;store values in Operand1 
	inc si				
	POP  AX
	POP  DX
	jmp ReadChar 
	RET

storOperation:
	mov byte ptr[si] , 0ffh 		;mark the end of operand1 by ffh 
	mov si, offset operation 		;get offset of operation address 
	mov [si],al 				;move it to memory 
	mov si ,offset operand2 	
		;mov dx,offset messege 		;print messege to check if jumps run well 
		;mov ah,9
		;int 21h 
	call ReadChar 

stopReading:
	mov byte ptr[si], 0ffh			;mark the end of operand2 by ffh


		;mov dx,offset messege 		;print messege to check 
		;mov ah,9
		;int 21h
		;mov di, offset operand1 	; this code to chack if the entered data is right

		;mov dx,0000h
		;mov ax,@data
		;mov dx,ax
		;mov bx,3 
		;mov al,[di+bx]
		;mov dl,al	
		;mov ah,6
		;int 21h 

		
	mov si, offset operand1 
	call BCDToBin				;covert data to bits (in operand1)
	mov operandBinary1, ax 
	mov si, offset operand2
	call BCDToBin				;covert data to bits (in operand2)
	mov operandBinary2, ax 
	
	mov al, operation 			;check the operation then jmp to its lable
	cmp al, '+'
	je Summation

	cmp al, '-'
	je Subtraction

	cmp al, '*'
	je Multiplication

	cmp al, '^'
	je Power

	cmp al, '/'
	je BasicDivision

	cmp al, 'U'
	je BasicDivision

	cmp al, 'D'
	je BasicDivision

Summation:

	mov ax, operandBinary1			;get converted data 
	mov bx, operandBinary2
	add ax,bx				;operation 
	mov si, offset result 
	call BinToBCD				;covert bits to BCD (OR ascii)
	call DispRes				;dispaly result
	call exitLable				;exit

Subtraction:

	mov ax, operandBinary1
	mov bx, operandBinary2
	sub ax,bx
	mov si, offset result 
	call BinToBCD
	call DispRes
	call exitLable				;exit 
	
Multiplication:

	mov ax, operandBinary1
	mov bx, operandBinary2
	mul bx					;result stored in dx:ax
	mov bx,ax				;move least 16 bit to bx
	mov ax,dx				;move most 16 bit to ax to convert it 
	mov si ,offset result
	call BinToBCD
	mov ax, bx				;return least 16 bit to ax to convert it 
	mov bx, cx				;store count of chars in most 16 bit 	
	dec si					;decrement si by 1 because its returned pluse 1 ; to return to exact position in memory 
	call BinToBCD
	add cx, bx
	dec cx
	call DispRes
	call exitLable

Power:
	mov cx, operandBinary2			;move number of iteration (^x)
	dec cx					;decrement it by 1 
	mov ax,operandBinary1			;move (y^) to ax 
	mov bx ,ax				;store value in bx because the result of multiplcation will store in ax 							
	Looop:
		mul bx
	loop looop				
	mov si ,offset result
	call BinToBCD
	call DispRes
	call exitLable				;exit 

BasicDivision:

	mov ax, operandBinary1
	mov bx, operandBinary2
	cwd					;expand value in  ax to dx:ax
	div bx
	push dx					;save value of reminder 
	
	mov dh, operation 

	cmp dh, '/'
	je Division

	cmp dh, 'U'
	je DivisionRoundUp	

reminderEqualZero:
	mov si ,offset result		;if user enter D neither / nor U 
	call BinToBCD
	call DispRes			;DivisionRoundDown
	jmp exitLable

Division:
	mov si ,offset result		;display integer 
	call BinToBCD
	call DispRes
		
	mov dl, '.' 	
	mov ah, 2
	int 21h
	pop dx				;get reminder 
	mov ax,100
	mul dx				;in ax 
	mov bx ,operandBinary2 
	div bx				;operandBinary2 
	mov si ,offset result		;
	call BinToBCD
	call DispRes	
	jmp exitLable			;exit 

DivisionRoundUp:
	pop dx
	cmp dx,0
	je reminderEqualZero
	inc ax				; increment by 1 
	jmp reminderEqualZero		;then move to reminderEqualZero to print result 

		;mov si ,offset result		 
		;call BinToBCD
		;call DispRes			
		;jmp exitLable	



BCDToBin:   
	PUSH DX
	PUSH CX
	PUSH BX
	MOV AX , 0 				; sum = 0 intially
NXT_D:     
	MOV  BL, [SI]
	CMP  BL, 0FFH				;this is the end of the operand 
	JE   BCD_DN			
        MOV  CX, 10
	MUL  CX    				; DX:AX = AX * 10	
	MOV  BH, 0
	ADD  AX, BX    				; AX = AX + digit = previous sum + digit
	INC  SI
	JMP  NXT_D

BCD_DN:     
	POP BX
        POP CX
        POP DX
	RET					;return 
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; input in AX
; converts to unpacked BCD in location starting at SI
; returns number of chars in CX
; Also SI points to first digit +1 ; must decrement to display
BinToBCD: 
         PUSH AX
         PUSH BX
         PUSH DX      
	 MOV  CX, 0

NXT_DIV: MOV  DX, 0	
         MOV  BX, 10
	 DIV  BX
	 MOV  [SI], DL
	 INC  SI
	 INC  CX  				; increment number of digits
	 CMP  AX, 0 
	 JNE  NXT_DIV
	 POP DX
	 POP BX
	 POP AX
	 RET					;return 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DispRes: 
         	CMP CX, 0
		JE  Disp_DN
		DEC SI
		MOV DL, [SI]
		ADD DL, 30H 	
		MOV AH, 2
		INT 21H
		DEC  CX
		JMP DispRes
Disp_DN: RET
			
exitLable:

.exit 
end 


