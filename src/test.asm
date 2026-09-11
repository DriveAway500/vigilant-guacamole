%include "lib/sys.asm"
%include "lib/file.asm"

section .bss
    input_buf resb 64
    file_buf  resb 1024
    fd_res    resq 1

section .text
    global _start

_start:
    println "FILE LOADING SYSTEM"
    println "TYPE FILE PATH"
    
    ; 1. Pass both buffer address and max length (macro requires 2 args)
    input input_buf, 64

    ; 2. Strip trailing newline character ('\n') from user input
    mov rsi, input_buf
.strip_loop:
    cmp byte [rsi], 0xA            ; Check for newline character
    je .null_terminate
    cmp byte [rsi], 0x0            ; Check for null byte
    je .open_step
    inc rsi
    jmp .strip_loop

.null_terminate:
    mov byte [rsi], 0              ; Replace '\n' with null terminator

.open_step:
    ; 3. Open requested file in read-only mode (O_RDONLY = 0)
    open_file input_buf, 0
    mov [fd_res], rax

    ; 4. Read up to 1024 bytes from file
    read_file [fd_res], file_buf, 1024
    push rax                       ; Save count of bytes read

    ; 5. Print file content using your println macro with 2 parameters
    pop rbx
    println file_buf, rbx

    ; 6. Close file descriptor
    close_file [fd_res]

    ; 7. Exit process with code 0
    exit 0
