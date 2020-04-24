

data segment
    buffer db 30, 0, 30 dup(0)
    array dw 100 dup(0) 
    array_len   dw ?
    start_msg   db "Enter count of array : ", 0Dh, 0Ah, '$'  
    CrLf        db 0Dh, 0Ah, '$'
    input_msg   db "Enter array :", 0Dh, 0Ah, '$'   
    output_msg  db "Mediana :", 0Dh, 0Ah, '$'    
    error       db "Input error", 0Dh, 0Ah, '$'
    pkey db "press any key...$"
ends

stack segment
    dw   128  dup(0)
ends

code segment
start:
; set segment registers:
    mov     ax, data
    mov     ds, ax
    mov     es, ax    
    
    lea     dx, start_msg
    call    print  
    
    mov     ah, 0Ah
    lea     dx, buffer
    int     21h  
    
    lea     dx, CrLf
    call    print

    push    array_len  
    call    parse
    pop     array_len
    
    mov     cx, array_len
    lea     si, array
    
    lea     dx, input_msg
    call    print   
    
input_of_array:
        
    mov     ah, 0Ah
    lea     dx, buffer
    int     21h   
    
    lea     dx, CrLf
    call    print 
    
    push    word ptr[si]
    call    parse
    pop     word ptr[si]
    add     si, 2
    
    loop    input_of_array  
    
    lea     si, array
    push    si
    push    array_len
    call    sort
    
    mov     ax, array_len
    mov     bl, 2
    idiv    bl 
    mov     ah, 0
    imul    bl
    add     si, ax
    
    push    array + si*2
    call    to_string  
    
    lea     dx, CrLf
    call    print 
    lea     dx, output_msg
    call    print
    
    lea     dx, buffer+2
    call    print  
    
    lea     dx, CrLf
    call    print 
            
exit:
    lea     dx, pkey
    mov     ah, 9
    int     21h        
    
        
    mov     ah, 1
    int     21h
    
    mov     ax, 4c00h 
    int     21h  
    
    sort proc
        push    bp 
        mov     bp, sp 
        push    si
        push    ax
        push    cx
        
        mov     cx, [bp+4]
        mov     si, [bp+6]   
        push    si
        dec     cx
        push    cx
            
    sort_loop:       
        mov     ax, word ptr[si]
        cmp     ax, word ptr[si+2]
        jle     nxt
        xchg    ax, word ptr[si+2]
        mov     word ptr[si], ax
  
    nxt:    
        add     si, 2
        loop    sort_loop
        pop     cx
        pop     si 
        push    si
        dec     cx
        push    cx 
        
        jcxz    break
        inc     cx
        loop    sort_loop

    break:
        pop     cx  
        pop     si
        pop     cx
        pop     ax
        pop     si
        pop     bp 
        ret     4                       
    sort endp        
    
    to_string proc 
        push    bp
        mov     bp, sp
        push    si
        push    di
        push    ax 
        push    bx
        push    cx
        push    dx
                       
        lea     si, buffer+2
        mov     di, si 
        mov     cx, 0 
        mov     ax, [bp+4]   
        push    ax
        mov     bx, 10 
        xor     dx, dx   
        and     ax, 8000h
        cmp     ax, 0
        pop     ax
        je      loop1
        not     ax
        inc     ax          
        mov     buffer+1, 1
        mov     buffer+2, 2Dh 
        inc     di        
          
    loop1:         
        mov     dx, 0
        idiv    bx 
        push    dx
        inc     cx
        cmp     ax, 0
        jnz     loop1
        
        mov     buffer+1, cl        
           
        
    loop2:
        pop     ax   
        add     ax, 30h
        stosb
        loop loop2 
        
        mov     byte ptr [di], '$' 
        
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        pop     di
        pop     si
        pop     bp
        ret 2
    to_string endp
    
    
    parse proc
        push    bp
        mov     bp, sp
        push    ax
        push    bx
        push    cx
        push    si 
        
        mov     dx, 0    
        push    dx

        xor     ax, ax
        mov     bx, 0
        
        mov     cx, 0
        mov     cl, [buffer+1]
        
        lea     si, buffer+2  
        
        cld 
               
        lodsb  
        dec     si 
        cmp     al, 2Dh         
        jne     For
        inc     si
        dec     cl  
        pop     dx
        mov     dl, 1
        push    dx
        
    
    For:
        lodsb   
        sub     al, '0'  
        cmp     al, 10
        jge     exception
        cmp     al, 0
        jl      exception  
        
        push    ax
        mov     ax, bx
        mov     bx, 10
        mul     bx 
        
        cmp     dx, 0
        jne     exception
        
        mov     bx, ax
        pop     ax
        add     bx, ax
        
        jo      border_check
        jmp     next
        
    border_check:
        cmp     bx, 8000h
        je      sign_chek
        jne     exception
            
    sign_chek:
        pop     dx
        cmp     dl,0  
        push    dx
        je      exception
        jmp     next 
           
        
    next:
        loop    For
                     
        pop     dx
        cmp     dl, 0
        jnz     negative
        
        mov     [bp+4], bx 
        jmp     end_function
        
    negative:     
        sub     bx, 1
        not     bx
        mov     [bp+4], bx 
        jmp     end_function
        
    exception:
        lea     dx, error
        call    print    
        jmp     exit
    end_function:       
        pop     si
        pop     cx
        pop     bx
        pop     ax
        pop     bp
        
        ret
    parse endp
        
             
    
    print       proc 
        
        push    ax
        mov     ah, 09h
        int     21h
        pop     ax
        ret
    print endp
ends

end start 
