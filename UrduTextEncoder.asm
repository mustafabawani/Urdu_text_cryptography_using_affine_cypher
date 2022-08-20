INCLUDE Irvine32.inc

.data
message1 BYTE "1. Encyption", 0Ah, 0 
message2 BYTE "2. Decryption", 0Ah, 0
message3 BYTE "0. Quit", 0Ah, 0
message4 BYTE "Invalid Input", 0Ah, 0
message5 BYTE "Your File Has been Encrypted", 0Ah, 0
message6 BYTE "Your File Has Been Decrypted", 0Ah, 0
choice BYTE "Enter your choice: ", 0Ah, 0
msg BYTE "Enter a file name: ", 0

UrduAlphabets WORD 0A7D8h,0A8D8h,0BED9h,0AAD8h,0B9D9h,0ABD8h,0ACD8h,086DAh, 0ADD8h,0AED8h,0AFD8h,088DAh,0B0D8h,0B1D8h,091DAh,0B2D8h, 098DAh,0B3D8h,0B4D8h,0B5D8h,0B6D8h,0B7D8h,0B8D8h,0B9D8h, 0BAD8h,081D9h,082D9h,0A9DAh,0AFDAh,084D9h,085D9h,086D9h, 088D9h,081DBh,0BEDAh,0A1D8h,08CDBh,092DBh

m =($-UrduAlphabets)/type urduAlphabets
a Dword ?
ainv Dword ?
b = 3
;e=ax+B mod m
filename byte 80 dup(?)
fileHandle HANDLE ?
wordsRead byte ?

buffer_size=100
buffer word buffer_size DUP(?)
message word buffer_size DUP(?)

Error Byte "ERROR OPENING THE FILE"

;filenameOut byte "text.txt"
;fileHandleOut HANDLE ?

.code

;====================================================
;================MAIN PROC===========================
MAIN Proc
    call computeVariable
    endless:
	    mov edx, offset message1
	    call writestring
	    mov edx, offset message2
	    call writestring
	    mov edx, offset message3
	    call writestring
	    call crlf
	    mov edx, offset choice
	    call writestring
	    call readint

	    cmp eax, 1
	    je encrypt
	    cmp eax, 2
    	je decrypt
        cmp eax,0
        je quit
        jmp invalidInput
    	encrypt:
	    	call encryption
            call clrscr
		    jmp endless
	    decrypt:
		    call decryption
            call clrscr
            jmp endless
        invalidInput:
            mov edx,offset message4
            call writestring
            call clrscr
            jmp endless
        quit:
               ret
main endp

;==============================================
;============= Encryption Proc=================
encryption Proc
	
	call reading	;reading from file
    cmp ecx,0
    JNE continueEncryption
    call crlf
    Call WaitMsg
    ret

    continueEncryption:
	call resolveSpacingIssue
    movzx ecx,wordsRead
    mov edi,0
   l1:
        mov bx,message[edi] ; MESSAGE TO SEARCH
        cmp  bx,02000h
        jE NotEncrypt
        cmp bx,094DBh
        jE NotEncrypt
        call linearSearching
        cmp eax,0FFFFFFFFh
        jE NotEncrypt
        ;KEY IN ESI

        ;e=ax+b mod m

        mov eax,esi     ;dividend
        mov bl,2        ;divisor
        div bl
        mul a
        add al,b
        mov bl,m
        div bl
        mov bl,2
        mov al,ah
        mul bl

        movzx esi,al
        mov ax,urduAlphabets[esi]
        mov message[edi],ax

        NotEncrypt:
            mov eax,0
            add edi,2
            dec ecx
    loop l1

	
	call convertToOriginal
    call writing


    mov edx, offset message5
    call writestring
    Call WaitMsg

	ret
encryption endp

;===============================================
;============== Decryption =====================
decryption PROC

	call reading	;reading from file
    cmp ecx,0
    JNE continueDecryption
    call crlf
    Call WaitMsg
    ret
    continueDecryption:
	    call resolveSpacingIssue
	    movzx ecx,wordsRead
        mov edi,0

        l1:
            mov bx,message[edi] ; MESSAGE TO SEARCH
            call linearSearching
            cmp eax,0FFFFFFFFh
            jE NotDecrypt
            mov eax,esi     ;dividend
            mov bl,2        ;divisor
            div bl
            ;x=ainverse(e-b)mod m
            sub al,b
            mul ainv
            mov bl,m
            div bl

            mov bl,2
            mov al,ah
            mul bl

            movzx esi,al
            mov ax,urduAlphabets[esi]
            mov message[edi],ax
            NotDecrypt:
        mov eax,0
        add edi,2
        dec ecx
    loop l1
    call convertToOriginal
    
    call writing
    
    mov edx, offset message6
	call writestring
    Call WaitMsg

decryption endp

;================================================
;-==============Linear searching=================
linearSearching Proc USES ecx edi
    mov ecx,m
    mov edi, offset urduAlphabets
    mov ax,bx
        RepNE scaSW 
        jE Found
    ;NotFound
        mov eax,0FFFFFFFFh
        ret
    Found:
    sub ecx,m
    neg ecx
    dec ecx
    mov eax,ecx
    mov ecx,type UrduAlphabets
    mul ecx
    mov esi,eax

    ret
linearSearching endp


;===============================================
;=========== Compute Variable ==================
computeVariable Proc
local temp:Dword
;computing a
mov temp,3
iterate:
    inc temp
    push temp
    push m
    call GCD
    add esp,8
    cmp eax,1
    JNE iterate
    mov eax,temp
    mov a,eax

;compute a inv
    call modInverse
    mov ainv,eax
    ret
computeVariable endp
;===============================================
;=============== GCD Recursive =================
GCD PROC
    push ebp
    mov ebp,esp
    mov eax,[ebp+12]    ;n1
    mov ebx,[ebp+8]     ;n2
    cmp ebx,0
    jE endRecursion
    mov edx,0
    div ebx         ;ax= n1/n2
    mov eax,ebx     ;eax=n1 (old n2)
    mov ebx,edx     ;ebx=n2 (new)
    recursive:
        push eax
        push ebx
        call GCD
        add esp,8
    endRecursion:
        mov esp,ebp
        pop ebp
ret
GCD ENDP

;================================================
;============= Modular Inverse ==================
modInverse PROC
push ebp
mov ebp,esp

mov ecx,1
mov edx,0
mov eax,a
mov ebx,m
div ebx
mov eax,edx

iterate:
    push eax
    cmp ecx,m
    JNL endLoop
    mul ecx
    div ebx
    cmp edx,1
    jE endLoop
    inc ecx 
    pop eax
jmp iterate
endLoop:
    mov eax,ecx
mov esp,ebp
pop ebp
ret
ModInverse Endp

;===============================================
;==============read from file===================
reading Proc
    
    call clrscr
	mov edx, offset msg
	call writestring

	;taking file name input
	Mov edx,offset filename
	Mov ecx, sizeof filename-1 
	Call ReadString

	;opening text file
	mov edx,offset filename
	call openinputfile
	mov fileHandle,eax
	
	; Check for errors whule opening file
	cmp eax,INVALID_HANDLE_VALUE                ; error opening file
	jne file_ok                                  
	mov edx,offset error
	call WRITESTRING
	mov ecx,0
    ret
	file_ok:
	mov edx,offset buffer		;saving text in buffer
	mov ecx,buffer_size
	call readFromFile
	mov wordsRead,al
	jnc ok					;error reading
	mov edx,offset error
	call writestring
    mov ecx,0
    ret
	ok:
	mov edx,offset buffer
	mov ecx,eax
	mov esi,0
	;closing file
	mov eax,filehandle
	call closeFile
    ret
reading endp


;===============================================
;============= Writing to file =================
writing Proc
mov edx,offset filename
call CreateOutputFile
mov filehandle,eax

cmp eax,INVALID_HANDLE_VALUE
jne File_Out_Ok
mov edx,offset error
mov ecx,0
call writestring
ret
jmp ok_OUT
File_Out_Ok:
    Mov eax,fileHandle
    Mov edx,offset buffer
    Movzx ecx,wordsRead
    Call writeToFile
    jnc ok_OUT
    mov edx,offset error
    mov ecx,0
    call writestring
    ret
ok_OUT:    
    
    mov eax,filehandle
    call closeFile
ret
writing endp


;=======================================================
;=============== resolving Spacing Issue ===============

resolveSpacingIssue proc
mov esi,offset buffer[0]
mov ebx,offset message

movzx ecx,wordsRead
mov al,20h
l1:
    cmp Byte Ptr [esi],al
    jNE continue
    inc ebx
    inc wordsread
    continue:
    mov dl,Byte Ptr [esi]
    mov Byte Ptr [ebx],dl
        inc ebx
        inc esi
loop l1
ret
resolveSpacingIssue endp

;=======================================================
;=============Convert to Original Reading Form==========
convertToOriginal PROC
mov esi,offset message
mov ebx,offset buffer

movzx ecx,wordsRead
mov al,00h
l1:
    cmp Byte Ptr [esi],al
    jE DonotWrite
	
    mov dx,[esi]
    mov [ebx],dx
	add ebx,1
    add esi,1
	jmp continue

	DonotWrite:
		inc esi
		dec wordsread
	continue:
		loop l1
ret
convertToOriginal endp
end main
