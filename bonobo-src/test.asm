section .data
    var_a dq 0
    var_b dq 0
    var_c dq 0
    var_result dq 0
    msg_0 db "yes", 10
    len_0 equ $ - msg_0
    msg_1 db "no", 10
    len_1 equ $ - msg_1

section .bss
    int_buffer resb 32

section .text
    global _start

_start:
    mov rax, 10
    push rax
    pop rax
    mov [var_a], rax
    mov rax, 20
    push rax
    pop rax
    mov [var_b], rax
    mov rax, 5
    push rax
    pop rax
    mov [var_c], rax
    mov rax, [var_a]
    push rax
    mov rax, [var_b]
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    mov rax, [var_c]
    push rax
    mov rax, 1
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    jle .L_else_0
    mov rax, [var_a]
    push rax
    mov rax, [var_b]
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    mov rax, [var_c]
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop rax
    mov [var_result], rax
    ; println("yes")
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_0
    mov rdx, len_0
    syscall
    mov rax, [var_result]
    push rax
    ; println expression [int]
    pop rax
    call print_int_var
    jmp .L_end_if_0
.L_else_0:
    ; println("no")
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_1
    mov rdx, len_1
    syscall
.L_end_if_0:

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

print_int_var:
    ; Expects integer value in RAX
    mov rbx, 10
    mov rcx, int_buffer + 31
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
    mov rdx, int_buffer + 31
    sub rdx, rcx
    inc rdx               ; Include newline byte
    mov rsi, rcx
    mov rax, 1            ; sys_write
    mov rdi, 1            ; stdout
    syscall
    ret
