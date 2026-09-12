section .data
    msg_0 db "hello from bonobo", 10
    len_0 equ $ - msg_0
    msg_1 db "top 2 hellos ever", 10
    len_1 equ $ - msg_1
    msg_2 db "top 3 hellos ever", 10
    len_2 equ $ - msg_2
    msg_3 db "top 4 hellos ever", 10
    len_3 equ $ - msg_3
    var_x dq 10
    var_b db "wtf", 10
    len_var_b equ $ - var_b
    int_buffer resb 32
    int_buffer_end equ $ - 1

section .text
    global _start

_start:
    ; println("hello from bonobo")
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_0
    mov rdx, len_0
    syscall
    ; println("top 2 hellos ever")
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_1
    mov rdx, len_1
    syscall
    ; println("top 3 hellos ever")
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_2
    mov rdx, len_2
    syscall
    ; println("top 4 hellos ever")
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_3
    mov rdx, len_3
    syscall
    ; println(x) [int]
    mov rax, [var_x]
    call print_int_var
    ; println(b) [str]
    mov rax, 1
    mov rdi, 1
    mov rsi, var_b
    mov rdx, len_var_b
    syscall

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

print_int_var:
    ; Expects integer value in RAX
    mov rbx, 10
    mov rcx, int_buffer_end
    mov byte [rcx], 10    ; Newline character at the end
    
.convert_loop:
    dec rcx
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rcx], dl
    test rax, rax
    jnz .convert_loop

    ; Calculate length
    mov rdx, int_buffer_end
    sub rdx, rcx
    inc rdx               ; Include newline byte
    mov rsi, rcx
    mov rax, 1            ; sys_write
    mov rdi, 1            ; stdout
    syscall
    ret
