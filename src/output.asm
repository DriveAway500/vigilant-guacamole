default rel

section .data
    str_val db 'hello fron bonobo', 10

section .text
    global _start

_start:
    ; sys_write(stdout, str_val, len)
    mov rax, 1
    mov rdi, 1
    lea rsi, [str_val]
    mov rdx, 18
    syscall

    ; sys_exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall
