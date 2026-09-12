; ==============================================================================
; File: codegen.asm
; Description: Code Generation Module
; ==============================================================================

default rel

%include "lib/file.asm"
%include "lib/ast.asm"

O_CREATE_FLAGS equ 577

section .data
    output_filename db "output.asm", 0

    asm_file_header db "default rel", 10, 10, "section .data", 10
    asm_file_header_len equ $ - asm_file_header

    asm_bss_header db 10, "section .bss", 10, "    int_buffer resb 32", 10
    asm_bss_header_len equ $ - asm_bss_header

    asm_text_header db 10, "section .text", 10, "    global _start", 10, 10, "_start:", 10
    asm_text_header_len equ $ - asm_text_header

    var_prefix db "    var_"
    var_prefix_len equ $ - var_prefix

    str_prefix db "    str_"
    str_prefix_len equ $ - str_prefix

    str_mid db " db '"
    str_mid_len equ $ - str_mid

    dq_mid db " dq "
    dq_mid_len equ $ - dq_mid

    str_suffix db "', 10", 10
    str_suffix_len equ $ - str_suffix

    newline_bytes db 10

    sys_write_str_prefix db "    mov rax, 1", 10, "    mov rdi, 1", 10, "    lea rsi, [str_"
    sys_write_str_prefix_len equ $ - sys_write_str_prefix

    sys_write_var_prefix db "    mov rax, 1", 10, "    mov rdi, 1", 10, "    lea rsi, [var_"
    sys_write_var_prefix_len equ $ - sys_write_var_prefix

    sys_write_len_prefix db "]", 10, "    mov rdx, "
    sys_write_len_prefix_len equ $ - sys_write_len_prefix

    sys_write_exec db 10, "    syscall", 10, 10
    sys_write_exec_len equ $ - sys_write_exec

    sys_write_var_int db "    mov rax, [var_"
    sys_write_var_int_len equ $ - sys_write_var_int

    sys_write_int_exec db "]", 10, "    lea rdi, [int_buffer + 31]", 10
                       db "    mov byte [rdi], 10", 10
                       db "    mov rbx, 10", 10
                       db "    mov rcx, 1", 10
                       db ".convert_loop:", 10
                       db "    xor rdx, rdx", 10
                       db "    div rbx", 10
                       db "    add dl, '0'", 10
                       db "    dec rdi", 10
                       db "    mov [rdi], dl", 10
                       db "    inc rcx", 10
                       db "    test rax, rax", 10
                       db "    jnz .convert_loop", 10
                       db "    mov rax, 1", 10
                       db "    mov rsi, rdi", 10
                       db "    mov rdi, 1", 10
                       db "    mov rdx, rcx", 10
                       db "    syscall", 10, 10
    sys_write_int_exec_len equ $ - sys_write_int_exec

    asm_footer db "    ; sys_exit(0)", 10
               db "    mov rax, 60", 10
               db "    xor rdi, rdi", 10
               db "    syscall", 10
    asm_footer_len equ $ - asm_footer

section .bss
    num_buf resb 20

section .text
    global generate_assembly_file

generate_assembly_file:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi                    ; Head ASTNode

    lea rbx, [output_filename]
    open_file rbx, O_CREATE_FLAGS
    test rax, rax
    js .error_exit
    mov r13, rax                    ; File descriptor

    write_file r13, asm_file_header, asm_file_header_len

    ; --- PASS 1: Data Section ---
    mov r14, r12
    xor r15, r15

.data_loop:
    test r14, r14
    jz .data_loop_end

    mov eax, dword [r14 + ASTNode.type]
    cmp eax, NODE_VAR_DECL
    je .emit_var_decl

    cmp eax, NODE_FUNCTION_CALL
    je .emit_literal_str

    jmp .next_data_node

.emit_var_decl:
    write_file r13, var_prefix, var_prefix_len
    mov rsi, [r14 + ASTNode.val_ptr]
    mov rdx, [r14 + ASTNode.pad]
    write_file r13, rsi, rdx

    mov r8, [r14 + ASTNode.arg_ptr]
    mov rax, [r14 + ASTNode.val_len]

    cmp rax, TYPE_INT
    je .emit_int_decl

.emit_str_decl:
    write_file r13, str_mid, str_mid_len
    mov rsi, [r8 + ASTNode.val_ptr]
    mov rdx, [r8 + ASTNode.val_len]
    write_file r13, rsi, rdx
    write_file r13, str_suffix, str_suffix_len
    jmp .next_data_node

.emit_int_decl:
    write_file r13, dq_mid, dq_mid_len
    mov rsi, [r8 + ASTNode.val_ptr]
    mov rdx, [r8 + ASTNode.val_len]
    write_file r13, rsi, rdx
    write_file r13, newline_bytes, 1
    jmp .next_data_node

.emit_literal_str:
    mov r8, [r14 + ASTNode.arg_ptr]
    test r8, r8
    jz .next_data_node

    mov eax, dword [r8 + ASTNode.type]
    cmp eax, NODE_STRING_LITERAL
    jne .next_data_node

    write_file r13, str_prefix, str_prefix_len
    mov rax, r15
    call write_number
    write_file r13, str_mid, str_mid_len

    mov rsi, [r8 + ASTNode.val_ptr]
    mov rdx, [r8 + ASTNode.val_len]
    write_file r13, rsi, rdx

    write_file r13, str_suffix, str_suffix_len
    inc r15

.next_data_node:
    mov r14, [r14 + ASTNode.next]
    jmp .data_loop

.data_loop_end:

    write_file r13, asm_bss_header, asm_bss_header_len
    write_file r13, asm_text_header, asm_text_header_len

    ; --- PASS 2: Code Section ---
    mov r14, r12
    xor r15, r15

.text_loop:
    test r14, r14
    jz .text_loop_end

    mov eax, dword [r14 + ASTNode.type]
    cmp eax, NODE_FUNCTION_CALL
    jne .next_text_node

    mov r8, [r14 + ASTNode.arg_ptr]
    test r8, r8
    jz .next_text_node

    mov eax, dword [r8 + ASTNode.type]
    cmp eax, NODE_STRING_LITERAL
    je .emit_print_literal

    cmp eax, NODE_IDENTIFIER
    je .emit_print_var

    jmp .next_text_node

.emit_print_literal:
    write_file r13, sys_write_str_prefix, sys_write_str_prefix_len
    mov rax, r15
    call write_number
    write_file r13, sys_write_len_prefix, sys_write_len_prefix_len

    mov rax, [r8 + ASTNode.val_len]
    inc rax
    call write_number

    write_file r13, sys_write_exec, sys_write_exec_len
    inc r15
    jmp .next_text_node

.emit_print_var:
    mov r9, r12                     ; Iterator for variable lookup
    mov rbx, [r8 + ASTNode.val_ptr] ; Target var name
    mov rcx, [r8 + ASTNode.val_len] ; Target var length

.find_var_decl:
    test r9, r9
    jz .next_text_node

    mov eax, dword [r9 + ASTNode.type]
    cmp eax, NODE_VAR_DECL
    jne .next_var

    mov rdx, [r9 + ASTNode.pad]
    cmp rdx, rcx
    jne .next_var

    mov rsi, [r9 + ASTNode.val_ptr]
    test rsi, rsi
    jz .next_var
    test rbx, rbx
    jz .next_var

    mov rdi, rbx
    push rcx

.cmp_loop:
    test rcx, rcx
    jz .cmp_match
    mov al, byte [rsi]
    mov ah, byte [rdi]
    cmp al, ah
    jne .cmp_fail
    inc rsi
    inc rdi
    dec rcx
    jmp .cmp_loop

.cmp_fail:
    pop rcx
    jmp .next_var

.cmp_match:
    pop rcx
    jmp .matched_var

.next_var:
    mov r9, [r9 + ASTNode.next]
    jmp .find_var_decl

.matched_var:
    mov rax, [r9 + ASTNode.val_len] ; Type (TYPE_INT or TYPE_STR)
    cmp rax, TYPE_INT
    je .print_int_var

.print_str_var:
    mov r10, rcx
    write_file r13, sys_write_var_prefix, sys_write_var_prefix_len
    write_file r13, rbx, r10
    write_file r13, sys_write_len_prefix, sys_write_len_prefix_len

    mov r10, [r9 + ASTNode.arg_ptr]
    mov rax, [r10 + ASTNode.val_len]
    inc rax
    call write_number

    write_file r13, sys_write_exec, sys_write_exec_len
    jmp .next_text_node

.print_int_var:
    mov r10, rcx
    write_file r13, sys_write_var_int, sys_write_var_int_len
    write_file r13, rbx, r10
    write_file r13, sys_write_int_exec, sys_write_int_exec_len
    
.next_text_node:
    mov r14, [r14 + ASTNode.next]
    jmp .text_loop

.text_loop_end:

    write_file r13, asm_footer, asm_footer_len
    close_file r13

.error_exit:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

write_number:
    push rbx
    push rcx
    push rdx
    push r15

    lea r15, [num_buf + 19]
    mov rbx, 10
    xor rcx, rcx

.conv_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec r15
    mov [r15], dl
    inc rcx
    test rax, rax
    jnz .conv_loop

    write_file r13, r15, rcx

    pop r15
    pop rdx
    pop rcx
    pop rbx
    ret