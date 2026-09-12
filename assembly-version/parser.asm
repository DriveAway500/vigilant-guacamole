; ==============================================================================
; File: parser.asm
; Description: Fixed Name & Identifier Parser
; ==============================================================================

default rel

%include "lib/mem.asm"
%include "lib/ast.asm"

section .bss
    parser_arena: resb Arena_size

section .text
    global parse_buffer

parse_buffer:
    push r12
    push r13
    push r14
    push r15
    push rbx

    mov r12, rdi         ; R12 = Buffer pointer
    mov r13, rsi         ; R13 = Remaining bytes

    lea rdi, [parser_arena]
    mov rax, [rdi + Arena.base]
    test rax, rax
    jnz .parse_init_vars

    mov rsi, 65536
    call arena_init

.parse_init_vars:
    xor r14, r14         ; Head = NULL
    xor r15, r15         ; Tail = NULL

.parse_loop:
    cmp r13, 0
    jle .parse_done

    mov al, byte [r12]
    cmp al, ' '
    je .advance_char
    cmp al, 10
    je .advance_char
    cmp al, 13
    je .advance_char
    cmp al, 9
    je .advance_char

    cmp r13, 4
    jl .advance_char
    cmp dword [r12], "let "
    je .parse_let_stmt

    cmp r13, 8
    jl .advance_char
    cmp dword [r12], "prin"
    jne .advance_char
    cmp dword [r12 + 4], "tln("
    je .parse_println_stmt

.advance_char:
    inc r12
    dec r13
    jmp .parse_loop

; --- Variable Declaration ---
.parse_let_stmt:
    add r12, 4
    sub r13, 4

    lea rdi, [parser_arena]
    mov rsi, ASTNode_size
    call arena_alloc
    mov rbx, rax

    mov dword [rbx + ASTNode.type], NODE_VAR_DECL
    mov qword [rbx + ASTNode.next], 0

    cmp dword [r12], "int "
    je .type_int
    cmp dword [r12], "str "
    je .type_str
    jmp .advance_char

.type_int:
    mov qword [rbx + ASTNode.val_len], TYPE_INT
    add r12, 4
    sub r13, 4
    jmp .skip_spaces_before_name

.type_str:
    mov qword [rbx + ASTNode.val_len], TYPE_STR
    add r12, 4
    sub r13, 4

.skip_spaces_before_name:
    cmp byte [r12], ' '
    jne .parse_name
    inc r12
    dec r13
    jmp .skip_spaces_before_name

.parse_name:
    mov qword [rbx + ASTNode.val_ptr], r12
    xor rcx, rcx

.scan_name:
    cmp rcx, r13
    jge .parse_done
    mov al, byte [r12 + rcx]
    cmp al, ' '
    je .name_done
    cmp al, '='
    je .name_done
    inc rcx
    jmp .scan_name

.name_done:
    mov qword [rbx + ASTNode.pad], rcx ; Save variable name length
    add r12, rcx
    sub r13, rcx

.find_eq:
    cmp byte [r12], '='
    je .found_eq
    inc r12
    dec r13
    jmp .find_eq

.found_eq:
    inc r12
    dec r13

.skip_spaces_val:
    cmp byte [r12], ' '
    jne .parse_val
    inc r12
    dec r13
    jmp .skip_spaces_val

.parse_val:
    lea rdi, [parser_arena]
    mov rsi, ASTNode_size
    call arena_alloc
    mov r10, rax
    mov qword [r10 + ASTNode.next], 0

    cmp byte [r12], '"'
    je .val_string

.val_int:
    mov dword [r10 + ASTNode.type], NODE_INT_LITERAL
    mov qword [r10 + ASTNode.val_ptr], r12
    xor rcx, rcx

.scan_int_val:
    cmp rcx, r13
    jge .int_val_done
    mov al, byte [r12 + rcx]
    cmp al, ';'
    je .int_val_done
    cmp al, ' '
    je .int_val_done
    cmp al, 10
    je .int_val_done
    cmp al, 13
    je .int_val_done
    inc rcx
    jmp .scan_int_val

.int_val_done:
    mov qword [r10 + ASTNode.val_len], rcx
    mov qword [rbx + ASTNode.arg_ptr], r10
    add r12, rcx
    sub r13, rcx
    jmp .finish_stmt

.val_string:
    inc r12
    dec r13
    mov dword [r10 + ASTNode.type], NODE_STRING_LITERAL
    mov qword [r10 + ASTNode.val_ptr], r12
    xor rcx, rcx

.scan_str_val:
    cmp rcx, r13
    jge .str_val_done
    mov al, byte [r12 + rcx]
    cmp al, '"'
    je .str_val_done
    inc rcx
    jmp .scan_str_val

.str_val_done:
    mov qword [r10 + ASTNode.val_len], rcx
    mov qword [rbx + ASTNode.arg_ptr], r10
    add r12, rcx
    sub r13, rcx
    inc r12
    dec r13

.finish_stmt:
    cmp byte [r12], ';'
    jne .append_ast
    inc r12
    dec r13

.append_ast:
    test r14, r14
    jnz .append_tail
    mov r14, rbx
    jmp .set_tail

.append_tail:
    mov qword [r15 + ASTNode.next], rbx

.set_tail:
    mov r15, rbx
    jmp .parse_loop

; --- Function Call ---
.parse_println_stmt:
    add r12, 8
    sub r13, 8

    lea rdi, [parser_arena]
    mov rsi, ASTNode_size
    call arena_alloc
    mov rbx, rax

    mov dword [rbx + ASTNode.type], NODE_FUNCTION_CALL
    mov qword [rbx + ASTNode.next], 0

    lea rdi, [parser_arena]
    mov rsi, ASTNode_size
    call arena_alloc
    mov qword [rax + ASTNode.next], 0

    ; Skip spaces inside println(...)
.skip_println_spaces:
    cmp byte [r12], ' '
    jne .check_arg_type
    inc r12
    dec r13
    jmp .skip_println_spaces

.check_arg_type:
    cmp byte [r12], '"'
    je .println_str

.println_ident:
    mov dword [rax + ASTNode.type], NODE_IDENTIFIER
    mov qword [rax + ASTNode.val_ptr], r12
    xor rcx, rcx

.scan_ident:
    cmp rcx, r13
    jge .ident_done
    mov dl, byte [r12 + rcx]
    cmp dl, ')'
    je .ident_done
    cmp dl, ' '
    je .ident_done
    cmp dl, 10
    je .ident_done
    cmp dl, 13
    je .ident_done
    inc rcx
    jmp .scan_ident

.ident_done:
    mov qword [rax + ASTNode.val_len], rcx
    mov qword [rbx + ASTNode.arg_ptr], rax
    add r12, rcx
    sub r13, rcx
    jmp .finish_println

.println_str:
    inc r12
    dec r13
    mov dword [rax + ASTNode.type], NODE_STRING_LITERAL
    mov qword [rax + ASTNode.val_ptr], r12
    xor rcx, rcx

.scan_println_str:
    cmp rcx, r13
    jge .str_println_done
    mov dl, byte [r12 + rcx]
    cmp dl, '"'
    je .str_println_done
    inc rcx
    jmp .scan_println_str

.str_println_done:
    mov qword [rax + ASTNode.val_len], rcx
    mov qword [rbx + ASTNode.arg_ptr], rax
    add r12, rcx
    sub r13, rcx
    inc r12
    dec r13

.finish_println:
    cmp byte [r12], ')'
    jne .check_semi
    inc r12
    dec r13

.check_semi:
    cmp byte [r12], ';'
    jne .append_ast
    inc r12
    dec r13
    jmp .append_ast

.parse_done:
    mov rax, r14
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret