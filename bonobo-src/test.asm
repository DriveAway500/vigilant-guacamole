section .data
    var_i dq 0
    var_running dq 0

section .bss
    int_buffer resb 32

section .text
    global _start

_start:
    mov rax, 0
    push rax
    pop rax
    mov [var_i], rax
    mov rax, 1
    push rax
    pop rax
    mov [var_running], rax
.L_while_start_0:
    mov rax, [var_running]
    push rax
    pop rax
    test rax, rax
    jz .L_while_end_0
    mov rax, [var_i]
    push rax
    ; println expression [int]
    pop rax
    call print_int_var
    mov rax, [var_i]
    push rax
    mov rax, 1
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop rax
    mov [var_i], rax
    mov rax, [var_i]
    push rax
    mov rax, 5
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    jne .L_end_if_1
    mov rax, 0
    push rax
    pop rax
    mov [var_running], rax
.L_end_if_1:
    jmp .L_while_start_0
.L_while_end_0:

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
