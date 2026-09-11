default rel

section .data
    str_0 db 'hello fron bonobo', 10
    str_1 db 'top 2 hellos ever', 10
    str_2 db 'top 3 hellos ever', 10
    str_3 db 'top 4 hellos ever', 10

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

    ; sys_exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall
