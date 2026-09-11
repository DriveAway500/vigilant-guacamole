default rel

%include "lib/sys.asm"
%include "lib/file.asm"
%include "parser.asm"

section .bss
    input_buf resb 64
    file_buf  resb 1024
    fd_res    resq 1

section .text
    global _start

_start:
    println "FILE LOADING SYSTEM"
    println "TYPE FILE PATH"
    
    ; 1. Read user input
    input input_buf, 64

    ; 2. Strip trailing newline character ('\n')
    mov rsi, input_buf
.strip_loop:
    cmp byte [rsi], 0xA
    je .null_terminate
    cmp byte [rsi], 0x0
    je .open_step
    inc rsi
    jmp .strip_loop

.null_terminate:
    mov byte [rsi], 0

.open_step:
    ; 3. Open file
    open_file input_buf, 0
    mov [fd_res], rax

    ; 4. Read file into file_buf
    read_file [fd_res], file_buf, 1024
    mov r12, rax                  ; Save count of bytes read into R12

    ; 5. Close file descriptor
    close_file [fd_res]

    ; 6. Parse the file content loaded in memory
    PARSE_BUFFER file_buf, r12    ; RAX contains the root ASTNode pointer

    ; 7. Exit process with code 0
    exit 0