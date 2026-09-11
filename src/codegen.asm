; ==============================================================================
; File: codegen.asm
; Description: Generator Module for x86_64 NASM Linux
; ==============================================================================

default rel

%include "lib/file.asm"

; --- AST DEFINITIONS ---
NODE_FUNCTION_CALL  equ 1
NODE_STRING_LITERAL equ 2

struc ASTNode
    .type:     resd 1
    .pad:      resd 1
    .val_ptr:  resq 1
    .val_len:  resq 1
    .arg_ptr:  resq 1
endstruc

; Open flags: O_WRONLY(1) | O_CREAT(64) | O_TRUNC(512) = 577
O_CREATE_FLAGS equ 577

section .data
    output_filename db "output.asm", 0

    asm_header db "default rel", 10, 10, "section .data", 10, "    str_val db '"
    asm_header_len equ $ - asm_header

    asm_mid db "', 10", 10, 10, "section .text", 10, "    global _start", 10, 10, "_start:", 10
            db "    ; sys_write(stdout, str_val, len)", 10
            db "    mov rax, 1", 10
            db "    mov rdi, 1", 10
            db "    lea rsi, [str_val]", 10
            db "    mov rdx, "
    asm_mid_len equ $ - asm_mid

    asm_footer db 10, "    syscall", 10, 10, "    ; sys_exit(0)", 10
               db "    mov rax, 60", 10
               db "    xor rdi, rdi", 10
               db "    syscall", 10
    asm_footer_len equ $ - asm_footer

section .bss
    len_buf resb 20

section .text
    global generate_assembly_file

generate_assembly_file:
    ; Input: RDI = pointer to root ASTNode
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi                   ; R12 = Root ASTNode (NODE_FUNCTION_CALL)

    ; --- 1. Open Output File ---
    lea rbx, [output_filename]
    open_file rbx, O_CREATE_FLAGS
    
    test rax, rax
    js .error_exit
    mov r13, rax                   ; R13 = File descriptor for output.asm

    ; --- 2. Write File Header ---
    write_file r13, asm_header, asm_header_len

    mov r14, [r12 + ASTNode.arg_ptr] ; R14 = Argument ASTNode
    test r14, r14
    jz .close_and_exit

    ; --- 3. Emit String Content ---
    mov rsi, [r14 + ASTNode.val_ptr]
    mov rdx, [r14 + ASTNode.val_len]
    write_file r13, rsi, rdx

    ; --- 4. Emit Text Section Setup ---
    write_file r13, asm_mid, asm_mid_len

    ; --- 5. Calculate and Emit String Length ---
    mov rax, [r14 + ASTNode.val_len]
    inc rax                        ; Length + 1 for newline character '\n'

    lea r15, [len_buf + 19]
    mov rbx, 10
    xor rcx, rcx                   ; Digit counter

.conv_loop:
    xor rdx, rdx
    div rbx                        ; rax / 10 -> rax = quotient, rdx = remainder
    add dl, '0'
    dec r15
    mov [r15], dl
    inc rcx
    test rax, rax
    jnz .conv_loop

    write_file r13, r15, rcx

    ; --- 6. Emit Exit Syscall Footer ---
    write_file r13, asm_footer, asm_footer_len

.close_and_exit:
    close_file r13

.error_exit:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret