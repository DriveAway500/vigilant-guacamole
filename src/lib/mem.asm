%ifndef MEM_ASM
%define MEM_ASM

; lib/mem.asm - Generic Arena Allocator Module
default rel

struc Arena
    .base: resq 1    ; Endereço base da memória
    .next: resq 1    ; Ponteiro para a próxima alocação livre
endstruc

section .text
    global arena_init
    global arena_alloc

; ------------------------------------------------------------------------------
; Initializes an Arena structure using sys_brk
; Input:  RDI = pointer to uninitialized Arena struct
;         RSI = initial capacity in bytes (e.g. 65536)
; ------------------------------------------------------------------------------
arena_init:
    push r12
    push r13

    mov r12, rdi            ; R12 = Arena struct pointer
    mov r13, rsi            ; R13 = Requested capacity

    ; 1. Get current break address
    mov rax, 12             ; sys_brk
    xor rdi, rdi
    syscall
    
    mov [r12 + Arena.base], rax
    mov [r12 + Arena.next], rax

    ; 2. Expand break address by capacity
    add rax, r13
    mov rdi, rax
    mov rax, 12             ; sys_brk
    syscall

    pop r13
    pop r12
    ret

; ------------------------------------------------------------------------------
; Allocates N bytes inside a specific Arena
; Input:  RDI = pointer to initialized Arena struct
;         RSI = bytes to allocate
; Output: RAX = pointer to allocated memory block
; ------------------------------------------------------------------------------
arena_alloc:
    ; Align size to 8-byte boundary
    add rsi, 7
    and rsi, ~7

    mov rax, [rdi + Arena.next]  ; Get current free offset
    add rsi, rax                 ; Calculate new free offset
    mov [rdi + Arena.next], rsi  ; Update Arena.next
    ret                          ; Return allocated block pointer in RAX

%endif 