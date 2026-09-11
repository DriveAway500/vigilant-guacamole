; parser.asm - Parser Module
default rel

%include "lib/mem.asm"

; --- AST STRUCT DEFINITION ---
NODE_FUNCTION_CALL  equ 1
NODE_STRING_LITERAL equ 2

struc ASTNode
    .type:     resd 1    ; NODE_* constant
    .pad:      resd 1    ; Alignment padding (8 bytes)
    .val_ptr:  resq 1    ; Pointer to string in buffer
    .val_len:  resq 1    ; String length
    .arg_ptr:  resq 1    ; Pointer to child ASTNode
endstruc

section .bss
    parser_arena: resb Arena_size  ; Instância estática da Arena para o parser

section .text
    global parse_buffer

; --- INTERFACE MACRO ---
%macro PARSE_BUFFER 2
    mov rdi, %1          ; 1st argument: buffer pointer
    mov rsi, %2          ; 2nd argument: buffer size
    call parse_buffer    ; Returns root ASTNode pointer in RAX
%endmacro

parse_buffer:
    ; Input:  RDI = buffer_ptr, RSI = buffer_size
    ; Output: RAX = pointer to root ASTNode

    push r12
    push r13
    push r14

    mov r12, rdi         ; R12 = buffer_ptr
    mov r13, rsi         ; R13 = buffer_size

    ; --- 1. Lazy-init parser's own arena if not yet initialized ---
    mov rax, [parser_arena + Arena.base]
    test rax, rax
    jnz .parse_start

    lea rdi, [parser_arena]
    mov rsi, 65536       ; 64KB capacity
    call arena_init

.parse_start:
    ; --- 2. Allocate root node ---
    lea rdi, [parser_arena]
    mov rsi, ASTNode_size
    call arena_alloc
    mov r14, rax         ; R14 = root ASTNode

    mov dword [r14 + ASTNode.type], NODE_FUNCTION_CALL
    mov qword [r14 + ASTNode.val_ptr], r12
    mov qword [r14 + ASTNode.val_len], 7

    ; --- 3. Allocate argument node ---
    lea rdi, [parser_arena]
    mov rsi, ASTNode_size
    call arena_alloc     ; RAX = argument ASTNode

    mov dword [rax + ASTNode.type], NODE_STRING_LITERAL
    lea rbx, [r12 + 9]   ; Advance past 'println("'
    mov qword [rax + ASTNode.val_ptr], rbx
    mov qword [rax + ASTNode.val_len], 9
    mov qword [rax + ASTNode.arg_ptr], 0

    ; --- 4. Link & Return ---
    mov qword [r14 + ASTNode.arg_ptr], rax
    mov rax, r14         ; Return root ASTNode in RAX

    pop r14
    pop r13
    pop r12
    ret