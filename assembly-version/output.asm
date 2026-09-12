default rel

section .data
    str_0 db 'hello from bonobo', 10
    str_1 db 'top 2 hellos ever', 10
    str_2 db 'top 3 hellos ever', 10
    str_3 db 'top 4 hellos ever', 10
    var_x dq 10
    var_b db 'wtf', 10

section .bss
    int_buffer resb 32

section .text
    global _start

_start:
    mov rax, 1
    mov rdi, 1
    lea rsi, [str_0]
    mov rdx, 18
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [str_1]
    mov rdx, 18
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [str_2]
    mov rdx, 18
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [str_3]
    mov rdx, 18
    syscall

    mov rax, [var_x]
    lea rdi, [int_buffer + 31]
    mov byte [rdi], 10
    mov rbx, 10
    mov rcx, 1
.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    inc rcx
    test rax, rax
    jnz .convert_loop
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    mov rdx, rcx
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [var_b]
    mov rdx, 4
    syscall

    ; sys_exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall
