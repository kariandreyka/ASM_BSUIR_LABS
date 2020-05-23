.286
.model small
.stack 100h
.data
	gameover_message db "GAME OVER", 0
	empty_gameover db "         ", 0
	score_message db "SCORE", 0
	score db "00000", 0
	buffer db 2000 dup(?)
	
	prev_snake_pos dw 2000
	head_pos dw 1000      
	snake_body_array dw 2000 dup(0)
	snake_body_symbol equ 219
	apple_pos_abs dw 0  
	key_code dw 0 
	get_apple_flag db 0
	
	random_number dw 0
	current_time db 0
	prev_time db 0
	time_interval  db 50
	object_collision_flag db 0
	end_game_flag db 0
	object_counter db 0
	dec_speed_flag db 0
	screen_attribute equ 0110100b
	TRUE equ 1
	FALSE equ 0
	border_upper_side equ 110
	border_bottom_side equ 1950
	border_left_side equ 110
	border_right_side equ 126
	horizontal_border_symbol equ 196
	vertical_border_symbol equ 179
	upper_left_border_corner equ 110
	upper_right_border_corner equ 126
	bottom_left_border_corner equ 1950
	bottom_right_border_corner equ 1966
	upper_left_border_corner_symbol equ 218
	upper_right_border_corner_symbol equ 191
	bottom_left_border_corner_symbol equ 192
	bottom_right_border_corner_symbol equ 217
.code

init_screen_mode proc
	pusha
	xor ax, ax
	mov ah,0h
	mov al,03h
	int 10h
	popa
	ret
init_screen_mode endp

sleep proc
	pusha
	mov ah, 0
	int 1ah
	mov bx, dx
	_wait:
		mov ah, 0
		int 1ah
		sub dx, bx
		cmp dx, si
		jb _wait
	popa
	ret
sleep endp

buffer_clear proc
    pusha
    mov bx, 0
	next_clear:	
	    mov byte ptr[buffer + bx], ' '
	    inc bx
	    cmp bx, 2000
	    jne next_clear
    popa
    ret
buffer_clear endp

buffer_write proc
	pusha
	mov di, offset buffer
	mov al, 80
	mul dl
	add ax, cx
	add di, ax
	mov byte ptr [di], bl
	popa
	ret
buffer_write endp

;input si - source address
;      di - buffer offset
buffer_write_string proc
	pusha
	write_string_loop:
		xor ax, ax
		lodsb 
		cmp al, 0
		je _exit_buffer_write_string
		mov byte ptr[buffer + di], al
		inc di
		jmp write_string_loop
	_exit_buffer_write_string:
		popa
		ret
buffer_write_string endp

buffer_render proc
    pusha
    mov ax, 0b800h
	mov es, ax
	mov di, offset buffer
	xor si, si
	next_render:
		xor bx, bx
		mov bl, byte ptr[di]
		mov bh, screen_attribute
		jmp write_render
	write_render:
		mov word ptr es:[si], bx
		inc di
		add si, 2
		cmp si, 4000
		jne next_render
    popa
	ret
buffer_render endp

hide_cursor proc
	pusha
	mov ah, 02h
	mov bh, 0
	mov dh, 26
	mov dl, 0
	int 10h
	popa
	ret
hide_cursor endp

random proc         
	pusha
	mov ah, 00h  ; interrupts to get system time        
	int 1ah      ; CX:DX now hold number of clock ticks since midnight      	
	mov  ax, dx
	xor  dx, dx
	mov  cx, 100    
	div  cx       ; here dx contains the remainder of the division - from 0 to 9
	mov word ptr[random_number], dx	
	popa    
	ret
random endp

show_gameover proc
	pusha 
	mov  key_code, 0
	call buffer_clear
	call buffer_render
	xor si, si
	xor di, di
	mov si, offset gameover_message
	mov di, 996
	call buffer_write_string
	call buffer_render
	_wait_for_key_gameover:
		mov si, 5
		call sleep
		mov si, offset empty_gameover
		mov di, 996
		call buffer_write_string
		call buffer_render
		call check_key_pressed
		cmp key_code, 0
		jne _exit_show_gameover
		jmp _continue_wait_for_key_gameover
		_continue_wait_for_key_gameover:
			mov si, 5
			call sleep
			mov si, offset gameover_message
			mov di, 996
			call buffer_write_string
			call buffer_render
			jmp _wait_for_key_gameover
	_exit_show_gameover: 
		popa
		ret
show_gameover endp

draw_border proc
	pusha
	mov di, 0
	next_x:
		mov byte ptr[buffer + di], 255
		mov byte ptr[buffer + border_upper_side + di], horizontal_border_symbol
		mov byte ptr[buffer + border_bottom_side + di], horizontal_border_symbol
		inc di
		cmp di, 16
		jnz next_x
		mov di, 0
	next_y:
		mov byte ptr[buffer + border_left_side + di], vertical_border_symbol
		mov byte ptr[buffer + border_right_side + di], vertical_border_symbol
		add di,80
		cmp di, 2000
		jl next_y
	corners:
		mov byte ptr[buffer + upper_left_border_corner], upper_left_border_corner_symbol
		mov byte ptr[buffer + upper_right_border_corner], upper_right_border_corner_symbol
		mov byte ptr[buffer + bottom_left_border_corner], bottom_left_border_corner_symbol
		mov byte ptr[buffer   + bottom_right_border_corner], bottom_right_border_corner_symbol
	popa
	ret
draw_border endp

draw_snake proc 
    pusha                                    
    xor     cx, cx
    mov     si, 0
    mov     di, word ptr[snake_body_array + si]
    mov     cl, byte ptr[object_counter]    
    cmp     cl, 0
    jne     loop1
    mov     byte ptr[buffer + di], snake_body_symbol
    jmp     tale
    loop1:           
        mov     byte ptr[buffer + di], snake_body_symbol 
        add     si, 2 
        mov     di, word ptr[snake_body_array + si] 
        loop loop1
    tale:
        mov     si, prev_snake_pos    
        mov     byte ptr[buffer + si], ' '
    popa  
    ret     
draw_snake endp     

generate_apple proc
    pusha  
    get_number:
    xor     dx, dx
    call    random 
    mov     ax, random_number
    mov     bx, 15
    div     bx
    add     dx, 191 
    mov     apple_pos_abs, dx
    xor     ax, ax
    xor     dx, dx
    
    call    random
    mov     ax, random_number
    mov     bx, 22
    div     bx 
    imul    dx, 80 
    add     apple_pos_abs, dx   
    xor     si, si
    xor     cx, cx
    mov     cl, byte ptr[object_counter] 
    inc     cx
    apple_loop:
        mov     ax, apple_pos_abs
        cmp     ax, word ptr[snake_body_array+si]
        je      get_number
        add     si, 2
        loop    apple_loop    
    popa
    ret 
generate_apple endp

draw_apple proc
    pusha 
    call    generate_apple
    mov     si, apple_pos_abs  
    mov     byte ptr[buffer + si], 5 
    popa
    ret
draw_apple endp

check_key_pressed proc
    pusha 
    mov     ah, 01h
	int     16h 
	jz      end_check
	mov     ah, 0h
	int     16h 
    cmp     ah, 48h ; up
	je      add_key
	cmp     ah, 50h ; down
	je      add_key
	cmp     ah, 4bh; left
	je      add_key
	cmp     ah, 4dh; right
	je      add_key 
	cmp     al, 27
	je      exit_func  
	jmp     end_check 
	add_key:
	    mov     key_code, ax
	    jmp     end_check	
	exit_func:
	    jmp     far ptr _exit 
	end_check:
        popa
        ret
check_key_pressed endp  

check_apple proc
    pusha
    mov     ax, word ptr[snake_body_array]
    cmp     ax, apple_pos_abs
    je      get_apple
    mov     get_apple_flag, FALSE
    jmp     end_check_apple  
    
    get_apple:
        mov     get_apple_flag, TRUE
        
    end_check_apple:
        popa
        ret
check_apple endp

update_snake proc
    pusha    
    call    check_time_left
    cmp     ax, 1
    je      j1
    jmp     _end_snake  
    
    j1:
        call    check_apple
        mov     al, get_apple_flag
        cmp     al, TRUE
        jne     skip
        mov     bl, byte ptr[object_counter] 
        inc     bl
        mov     byte ptr[object_counter], bl 
        call    draw_apple   
        jmp     next   
    
    skip:   
        mov     al, byte ptr[object_counter]  
        imul    ax, 2
        mov     si, ax
        mov     bx, word ptr[snake_body_array+si]
        mov     prev_snake_pos, bx
           
    next:            
        xor     si, si    
        mov     al, byte ptr[object_counter]  
        imul    ax, 2
        mov     si, ax
        mov     cl, byte ptr[object_counter]   
        cmp     cl, 0  
        je      continue
        update_loop:
            mov     bx, word ptr[snake_body_array+si-2] 
            mov     word ptr[snake_body_array+si], bx 
            sub     si, 2
            loop    update_loop       
            
    continue:    
        call    check_key_pressed
        mov     ax, key_code      
    
        cmp     ah, 48h ; up
	    je      up
	    cmp     ah, 50h ; down
	    je      down
	    cmp     ah, 4bh; left
	    je      left
	    cmp     ah, 4dh; right
	    je      right
	    jmp     _end_snake
	
	up:          
	    cmp     word ptr[snake_body_array], 240
	    jl      toBottom
	    sub     word ptr[snake_body_array], 80 
	    call    draw_snake 
	    jmp     _end_snake
	    toBottom:
	        add     word ptr[snake_body_array], 1680 
	        call    draw_snake    
	    jmp     _end_snake
	    
	down:               
	    cmp     word ptr[snake_body_array], 1840
	    jg      toTop  
	    add     word ptr[snake_body_array], 80  
	    call    draw_snake 
	    jmp     _end_snake
	    toTop:
	        sub     word ptr[snake_body_array], 1680
	        call    draw_snake     
	    jmp     _end_snake
	    
	left:  
	    mov     ax, [snake_body_array]
	    mov     bx, 80                  
	    xor     dx, dx
	    div     bx  
	    cmp     dx, 31
	    je      toRight              
	    sub     word ptr[snake_body_array], 1  
	    call    draw_snake
	    jmp     _end_snake
	    toRight:
	        add     word ptr[snake_body_array], 14
	        call    draw_snake     
	    jmp     _end_snake
	    
	right:  
	    mov     ax, [snake_body_array]
	    mov     bx, 80                  
	    xor     dx, dx
	    div     bx  
	    cmp     dx, 45
	    je      toLeft      
	    add     word ptr[snake_body_array], 1    
	    call    draw_snake
	    jmp     _end_snake 
	    toLeft:
	        sub     word ptr[snake_body_array], 14
	        call    draw_snake     
	    jmp     _end_snake
	     
	_end_snake:
        popa
        ret  
update_snake endp

get_counters_value proc
	pusha
	xor ax, ax
	xor cx, cx
	xor dx, dx
	mov ah, 2ch
	int 21h
	mov byte ptr[current_time], dl
	popa
	ret
get_counters_value endp

drop_counter proc
	pusha
	xor cx, cx
	xor dx, dx
	mov ah, 01h
	int 1ah
	popa
	ret
drop_counter endp

check_time_left proc
	pusha
	call get_counters_value
	xor ax, ax
	xor bx, bx
	xor dx, dx
	mov al, byte ptr[prev_time]
	mov bl, byte ptr[current_time]
	cmp bx, ax
	jae _sub_from_bx
	jb _sub_from_ax
	_sub_from_ax:
		mov cx, 99
		sub cx, ax
		add bx, cx
		jmp compare_with_time_interval
	_sub_from_bx:
		sub bx, ax
		jmp compare_with_time_interval
	compare_with_time_interval:
		mov dl, byte ptr[time_interval]
		jmp compare_time
	compare_time:
		cmp bx, dx
		jae _true
		jmp _false
	_true:
		xor dx, dx
		mov dl, byte ptr[current_time]
		mov byte ptr[prev_time], dl
		popa
		mov ax, 1
		jmp _exit_check_time_left
	_false:
		popa
		mov ax, 0
		jmp _exit_check_time_left
	_exit_check_time_left:
		ret
check_time_left endp

check_snake_collision proc
	pusha
	xor ax, ax
	xor bx, bx  
	xor dx, dx 
	
	xor cx, cx
	mov cl, byte ptr[object_counter] 
	cmp cl, 0
	je  _exit_check_snake_collision
	mov ax, word ptr[snake_body_array]
	xor si, si
	mov si, 2 
	check_collision_loop:
	    cmp ax, word ptr[snake_body_array+si]
	    je  collision_detected
	    add si, 2
	    loop check_collision_loop 
	    
	jmp _exit_check_snake_collision
	collision_detected:
		mov byte ptr[end_game_flag], TRUE
	_exit_check_snake_collision:
		popa
		ret
check_snake_collision endp

increase_speed proc
	pusha
	xor ax, ax
	mov al, byte ptr[object_counter]
	xor bx, bx
	mov bl, 5
	div bl
	cmp ah, 0
	je decrease_time_interval
	jne _reset_speed_flag
	decrease_time_interval:
		mov bl, byte ptr[dec_speed_flag]
		cmp bl, TRUE
		je _exit_increase_speed
		mov al, byte ptr[time_interval]
		cmp al, 20
		jle _sub_one
		jmp _sub_five
		_sub_one:
			sub al, 1
			jmp check_to_zero 
		_sub_five:
			sub al, 5
			jmp check_to_zero
		check_to_zero:
			cmp al, 0
			je add_one
			jmp continue_decrease_speed
		add_one:
			add al, 1
			jmp continue_decrease_speed
		continue_decrease_speed:
			mov byte ptr[time_interval], al
			mov byte ptr[dec_speed_flag], 1
			jmp _exit_increase_speed
	_reset_speed_flag:
		mov byte ptr[dec_speed_flag], 0
		jmp _exit_increase_speed
	_exit_increase_speed:
		popa
		ret
increase_speed endp

itoa proc
    pusha
    xor di, di
    xor si, si
	xor ax, ax
	xor bx, bx
    mov di, offset score
    add di, 4
    mov al, byte ptr[object_counter]
    _outer_loop_:
       mov bx, 10
	   xor dx, dx
       div bx
       add dx, '0'
       mov byte ptr[di], dl
       dec di
       cmp ax, 0
       je _ret_itoa
       jmp _outer_loop_
    _ret_itoa:       
    	popa
    	ret
itoa endp

print_score proc
	pusha
	xor si, si
	xor di, di
	call itoa
	mov si, offset score_message
	mov di, 128
	call buffer_write_string
	mov si, offset score
	mov di, 134
	call buffer_write_string
	call buffer_render
	popa
	ret
print_score endp

_start:
    mov     ax, @data
    mov     ds, ax
	call    init_screen_mode
	call    hide_cursor
    call    buffer_clear
    call    buffer_render
	call    draw_border
	call    buffer_render 
	mov     word ptr[snake_body_array], 1000 
	call    draw_snake
	call    buffer_render
	call    draw_apple
	call    buffer_render
	main_loop:
		call    print_score 		    
		call    update_snake
		call check_snake_collision
		xor ax, ax
		mov al, byte ptr[end_game_flag]
		cmp ax, TRUE
		je _exit
		call increase_speed
		call    buffer_render
	    jmp main_loop
_exit:
call buffer_clear
call buffer_render
call show_gameover
mov ah, 4ch
int 21h
end _start