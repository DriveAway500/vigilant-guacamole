; ==============================================================================
; File: codegen.asm
; Description: Generator Module for x86_64 NASM Linux (Multiple Statements)
; ==============================================================================

default rel

%include "lib/file.asm"
%include "lib/ast.asm"

O_CREATE_FLAGS equ 577

section .data
    output_filename db "output.asm", 0

    asm_file_header db "default rel", 10, 10, "section .data", 10
    asm_file_header_len equ $ - asm_file_header

    asm_text_header db 10, "section .text", 10, "    global _start", 10, 10, "_start:", 10
    asm_text_header_len equ $ - asm_text_header

    str_prefix db "    str_"
    str_prefix_len equ $ - str_prefix

    str_mid db " db '"
    str_mid_len equ $ - str_mid

    str_suffix db "', 10", 10
    str_suffix_len equ $ - str_suffix

    write_sys_call db "    mov rax, 1", 10, "    mov rdi, 1", 10, "    lea rsi, [str_"
    write_sys_call_len equ $ - write_sys_call

    write_len_prefix db "]", 10, "    mov rdx, "
    write_len_prefix_len equ $ - write_len_prefix

    write_syscall_exec db 10, "    syscall", 10, 10
    write_syscall_exec_len equ $ - write_syscall_exec

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
    ; Input: RDI = pointer to head ASTNode
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi                    ; R12 = Head ASTNode

    ; Open output file
    lea rbx, [output_filename]
    open_file rbx, O_CREATE_FLAGS
    test rax, rax
    js .error_exit
    mov r13, rax                    ; R13 = Output File Descriptor

    ; Write file header (.data section start)
    write_file r13, asm_file_header, asm_file_header_len

    ; --- PASS 1: Generate Data Section (.data) ---
    mov r14, r12                    ; R14 = Current AST node iterator
    xor r15, r15                    ; R15 = String index counter

.data_loop:
    test r14, r14
    jz .data_loop_end

    ; Store arg_ptr into R8 to survive write_file/write_number calls
    mov r8, [r14 + ASTNode.arg_ptr]
    test r8, r8
    jz .next_data_node

    ; Emit: "    str_<index> db '"
    write_file r13, str_prefix, str_prefix_len
    mov rax, r15
    call write_number
    write_file r13, str_mid, str_mid_len

    ; Emit string content using saved R8 pointer
    mov rsi, [r8 + ASTNode.val_ptr]
    mov rdx, [r8 + ASTNode.val_len]
    write_file r13, rsi, rdx

    ; Emit: "', 10\n"
    write_file r13, str_suffix, str_suffix_len

    inc r15                         ; Increment string index

.next_data_node:
    mov r14, [r14 + ASTNode.next]
    jmp .data_loop

.data_loop_end:

    ; Write .text section header
    write_file r13, asm_text_header, asm_text_header_len

    ; --- PASS 2: Generate Code Section (.text) ---
    mov r14, r12                    ; Reset iterator to head
    xor r15, r15                    ; Reset string index counter

.text_loop:
    test r14, r14
    jz .text_loop_end

    mov r8, [r14 + ASTNode.arg_ptr]
    test r8, r8
    jz .next_text_node

    ; Emit sys_write code block
    write_file r13, write_sys_call, write_sys_call_len
    mov rax, r15
    call write_number
    write_file r13, write_len_prefix, write_len_prefix_len

    ; Emit string length + 1 (for line break '\n')
    mov rax, [r8 + ASTNode.val_len]
    inc rax
    call write_number

    ; Emit syscall instruction
    write_file r13, write_syscall_exec, write_syscall_exec_len

    inc r15

.next_text_node:
    mov r14, [r14 + ASTNode.next]
    jmp .text_loop

.text_loop_end:

    ; Write sys_exit footer
    write_file r13, asm_footer, asm_footer_len

    close_file r13

.error_exit:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; ==============================================================================
; Helper Function: write_number
; Converts RAX to string and writes to file (R13 = fd)
; ==============================================================================
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