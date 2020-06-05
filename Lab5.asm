.286
.model small
.stack 100h

.data
    chunck_length equ 1024
    chunk db chunck_length dup(0)
    byte_readed dw 0

    word_buffer_length equ 50
    word_buffer db word_buffer_length + 1 dup(0)
    buffer_position dw 0
    word_buffer_position dw 0
    letters_count dw 0

    file_path db 64 dup(0)
    file_name db "file.txt", 0

    file_path_to_create db "F:/temp.txt", 0

    word_to_search db word_buffer_length + 1 dup(0)

    move_cursor db 10, 13, '$'

    error_code dw 0
    error_code_string db "00000", '$', 0
    error_message db "Error occurred. Error code : ", '$'

    file_descriptor_in dw 0
    file_descriptor_out dw 0

    deviders_string db ' ', ',' , '.' , '!' , '?', ':', 59, 9, 0

    EOF db 0
    EOS db 0
    word_founded_flag db 0


    strings_counter dw 0
    strings_counter_string db  "00000", '$', 0

    true equ 1
    false equ 0

.code

    ;input: ax - digit to convert
    ;       si - buffer to hold digit
    ;output: in buffer di - symbol representation of digit
    itoa proc
        pusha
        ;xor si, si
	    ;xor ax, ax
	    xor bx, bx
        ;mov di, offset error_code_string
        mov bx, ax
        call strlen
        mov ax, bx
        sub cx, 2
        add si, cx
        ;mov ax, word ptr[error_code]
        _outer_loop_:
           mov bx, 10
	       xor dx, dx
           div bx
           add dx, '0'
           mov byte ptr[si], dl
           dec si
           cmp ax, 0
           je _ret_itoa
           jmp _outer_loop_
        _ret_itoa:       
        	popa
        	ret
    itoa endp

    handle_error proc
        pusha
        mov word ptr[error_code], ax
        mov si, offset error_code_string
        call itoa
        popa
        ret
    handle_error endp

    output_error proc
        pusha
        xor dx, dx
        mov ah, 09h
        mov dx, offset error_message
        int 21h
        mov ah, 09h
        mov dx, offset error_code_string
        int 21h
        mov ah, 09h
        mov dx, offset move_cursor
        int 21h
        popa
        ret
    output_error endp

    clear_chunck proc
        pusha
        xor di, di
        clear_chunck_loop:
            mov byte ptr[chunk + di], 0
            inc di
            cmp di, chunck_length + 1
            jb clear_chunck_loop
        popa
        ret
    clear_chunck endp

    parse_command_line proc
        pusha
        xor ax, ax
        xor bx, bx

        mov bl, byte ptr es:[80h]
        cmp bl, 1
        jbe _exit_parse_command_line

        mov si, 82h
        mov di, offset file_path
        parse_path:
            mov al, byte ptr es:[si]
            cmp al, ' '
            je end_parse_path
            cmp al, 0dh
            je end_parse_path

            mov byte ptr[di], al
            inc si
            inc di
            jmp parse_path

        end_parse_path:
            mov byte ptr[di], 0
            cmp al, 0dh
            je continue_end_parse_path
            jmp increment_cmd_offset
            increment_cmd_offset:
                inc si
            continue_end_parse_path:
                mov di, offset word_to_search
                jmp parse_word

        parse_word:
            mov al, byte ptr es:[si]
            cmp al, ' '
            je end_parse_word
            cmp al, 0dh
            je end_parse_word

            mov byte ptr[di], al
            inc si
            inc di
            jmp parse_word

        end_parse_word:
            mov byte ptr[di], 0
            jmp _exit_parse_command_line

        _exit_parse_command_line:
            popa
            ret
    parse_command_line endp
    
    ;input : dx - offset string, which holds file path
    ;        di - offset variable(word size), to hold file descriptor
    ;output : in variable - file descriptor
    create_file proc
        pusha
        xor ax, ax
        xor cx, cx
        ;xor dx, dx

        mov ah, 3ch
        mov cx, 00000000b
        ;mov dx, offset file_path_to_create
        int 21h

        jc create_file_error
        ;mov word ptr[file_descriptor_out], ax
        mov word ptr[di], ax
        jmp _exit_create_file
        create_file_error:
            call handle_error
            call output_error
            jmp _exit_create_file
    
        _exit_create_file:
            popa
            ret
    create_file endp

    ;input : di - offset variable(word size) to hold file descriptor
    ;        dx - offset string, which holds file path
    ;output : in varible, which offset was holded in di - file descriptor
    open_exist_file proc
        pusha
        xor ax, ax
        ;xor dx, dx
        xor cx, cx

        mov ah, 3dh
        mov al, 0
        ;mov dx, offset file_path
        int 21h

        jc open_file_error
        ;mov word ptr[file_descriptor_in], ax
        mov word ptr[di], ax
        jmp _exit_open_file
        open_file_error:
            call handle_error
            call output_error
            jmp _exit_open_file
            
        _exit_open_file:
            popa
            ret
    open_exist_file endp

    ;input : bx - file descriptor
    ;output : byte_readed - count of bites, which was readed
    ;         EOF = 1 if end of file was reached
    read_from_file proc
        pusha
        xor ax, ax
        ;xor bx, bx
        xor cx, cx
        xor dx, dx

        mov ah, 3fh
        ;mov bx, word ptr[file_descriptor_in]
        mov cx, chunck_length
        mov dx, offset chunk
        int 21h

        jc read_from_file_error
        mov word ptr[byte_readed], ax
        cmp ax, cx
        jb set_EOF
        jmp _exit_read_from_file

        read_from_file_error:
            call handle_error
            call output_error
            jmp _exit_read_from_file

        set_EOF:
            mov byte ptr[EOF], true
            jmp _exit_read_from_file

        _exit_read_from_file:
            popa
            ret
    read_from_file endp

    ;input: bx - file descriptor
    ;       cx - counts of bytes to write
    ;       dx - source buffer offset
    write_to_file proc
        pusha
        xor ax, ax
        ;xor bx, bx
        ;xor cx, cx
        ;xor dx, dx

        mov ah, 40h
        ;mov bx, word ptr[file_descriptor_out]
        ;mov cx, word ptr[byte_readed]
        ;mov dx, offset chunk
        int 21h

        jc write_to_file_error
        jmp _exit_write_to_file
        write_to_file_error:
            call handle_error
            call output_error
            jmp _exit_write_to_file
            
        _exit_write_to_file:
            popa
            ret
    write_to_file endp

    ;input :
    ;bx - file descriptor
    close_file proc
        pusha
        xor ax, ax

        mov ah, 3eh
        jc close_file_error
        jmp _exit_close_file
        close_file_error:
            call handle_error
            call output_error
            jmp _exit_write_to_file
            
        _exit_close_file:
            popa
            ret
    close_file endp

    ;input al - symbol
    ;output if chacracter is divider in stack - true(1), if not in stack - false(0)
    compare_character_with_diveders proc
        pusha
        xor di, di
        xor bx, bx

        compare_character_loop:
            mov bl, byte ptr[deviders_string + di]
            cmp bl, 0
            je character_is_not_divider
            cmp al, bl
            je character_is_divider
            inc di
            jmp compare_character_loop
        character_is_divider:
            popa
            pop bp
            push true
            push bp
            jmp _exit_compare_character
        character_is_not_divider:
            popa
            pop bp
            push false
            push bp
            jmp _exit_compare_character
        _exit_compare_character:        
            ret
    compare_character_with_diveders endp

    ;input: di - position in buffer
    ;       si - position in word buffer
    ;output: in word_buffer - word
    ;         in stack - new position in buffer or -1 if buffer ends
    get_word_from_buffer proc
        pusha
        xor ax, ax
        xor cx, cx
        ;xor si, si
        mov cx, di
        add cx, 50

        word_loop:
            cmp di, word ptr[byte_readed]
            jae buffer_ends
            cmp di, cx
            jae set_new_position_in_buffer
            mov al, byte ptr[chunk + di]
            cmp al, 13
            je  find_CR
            cmp al, 10
            je set_EOS
            
            call compare_character_with_diveders
            pop bx
            inc di
            cmp bx, false
            je write_to_word_buffer
            jmp set_new_position_in_buffer

        write_to_word_buffer:
            mov byte ptr[word_buffer + si], al
            inc si
            jmp word_loop

        set_new_position_in_buffer:
            mov word ptr[buffer_position], di
            mov byte ptr[word_buffer + si], 0
            mov word ptr[letters_count], si
            mov word ptr[word_buffer_position], 0
            jmp _exit_get_word

        find_CR:
            inc di
            jmp word_loop
        set_EOS:
            mov byte ptr[EOS], true
            add di, 1
            mov word ptr[buffer_position], di
            mov byte ptr[word_buffer + si], 0
            mov word ptr[letters_count], si
            mov word ptr[word_buffer_position], si
            jmp _exit_get_word

        buffer_ends:
            mov word ptr[buffer_position], -1
            mov byte ptr[word_buffer + si], 0
            mov word ptr[letters_count], si
            mov word ptr[word_buffer_position], si
            jmp _exit_get_word

        _exit_get_word:
            popa
            ret
    get_word_from_buffer endp

    try_to_increase_strings_counter proc
        pusha
        xor ax, ax

        mov byte ptr[EOS], false
        mov al, byte ptr[word_founded_flag]
        cmp al, false
        je increase_strings_counter
        jmp _exit_increase_counter
        increase_strings_counter:
            mov ax, word ptr[strings_counter]
            inc ax
            mov word ptr[strings_counter], ax
            jmp _exit_increase_counter
        
        _exit_increase_counter:
            popa
            ret
    try_to_increase_strings_counter endp

    ;input: si - offset source string
    ;output: cx - string length
    strlen proc
        push si
        xor ax, ax
        xor cx, cx
        strlen_loop:
            mov al, byte ptr[si]
            cmp al, 0
            je _exit_strlen
            inc si
            inc cx
            jmp strlen_loop

        _exit_strlen:
            pop si
            ret
    strlen endp

    ;input: si - offset first string
    ;       di - offset second string
    ;output: in stack false(if strings not equal) or true(if strings equal)
    strcmp proc
        pusha
        cld
        xor dx, dx
        call strlen
        mov bx, cx
        mov dx, si
        mov si, di
        call strlen
        cmp bx, cx
        jne strings_not_equal

        mov si, dx
        repe cmpsb
        jne strings_not_equal
        jmp strings_equal

        strings_not_equal:
            popa
            pop bp
            push false
            push bp
            jmp _exit_strcmp
        
        strings_equal:
            popa
            pop bp
            push true
            push bp
            jmp _exit_strcmp

        _exit_strcmp:
            ret
    strcmp endp

    handle_buffer proc
        pusha
        xor ax, ax
        xor di, di

        buffer_loop:
            mov di, word ptr[buffer_position]
            mov si, word ptr[word_buffer_position]
            call get_word_from_buffer

            mov ax, word ptr[buffer_position]
            cmp ax, -1
            je _exit_handle_buffer
            mov di, offset word_buffer
            mov si, offset word_to_search
            call strcmp
            pop ax
            cmp ax, true
            je set_word_founded_flag
        continue_buffer_loop:
            mov al, byte ptr[EOS]
            cmp al, true
            je string_counter_proc
            jmp buffer_loop
            string_counter_proc:
                call try_to_increase_strings_counter
                mov byte ptr[word_founded_flag], false
            jmp buffer_loop

        set_word_founded_flag:
            mov byte ptr[word_founded_flag], true
            jmp continue_buffer_loop

        set_word_founded_flag_end:
            mov byte ptr[word_founded_flag], true
            jmp continue_exit_handle_buffer

        _exit_handle_buffer:
            mov di, offset word_buffer
            mov si, offset word_to_search
            call strcmp
            pop ax
            cmp ax, true
            je set_word_founded_flag_end
            continue_exit_handle_buffer:
                call try_to_increase_strings_counter
                mov byte ptr[word_founded_flag], false
                popa
                ret
    handle_buffer endp

    print_counter proc
        pusha
        mov ax, word ptr[strings_counter]
        mov si, offset strings_counter_string
        call itoa
        xor dx, dx
        mov dx, offset strings_counter_string
        mov ah, 09h
        int 21h
        mov ah, 09h
        mov dx, offset move_cursor
        int 21h
        popa
        ret
    print_counter endp

    _start:
        mov ax, @data
        mov ds, ax
        call parse_command_line
        mov bl, byte ptr[word_to_search]
        cmp bl, 0
        je _exit
        mov es, ax
        mov di, offset file_descriptor_in
        mov dx, offset file_path
        call open_exist_file
        mov ax, word ptr[error_code]
        cmp ax, 0
        ja _exit
        
        file_loop:
            mov bx, word ptr[file_descriptor_in]
            call read_from_file
            call handle_buffer
            mov word ptr[buffer_position], 0
            mov ax, word ptr[strings_counter]
            dec ax
            mov word ptr[strings_counter], ax
            xor ax, ax
            mov al, byte ptr[EOF]
            cmp al, true
            je end_file_loop
            jmp file_loop
        
        end_file_loop:
        ;call print_counter
        mov ax, word ptr[strings_counter]
        inc ax
        mov word ptr[strings_counter], ax
        xor bx, bx
        mov bx, word ptr[file_descriptor_in]
        call close_file
    _exit:
        call print_counter
        mov ah, 4ch
        int 21h
    end _start