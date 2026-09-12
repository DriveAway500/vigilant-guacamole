%ifndef FILE_ASM
%define FILE_ASM

; ==============================================================================
; File: lib/file.asm
; Description: Macros for Linux x86_64 file operations and standard I/O
; ==============================================================================

; --- Macro: open_file ---
; Arguments:
; %1: Pointer to filename (null-terminated)
; %2: Flags (e.g., 0 for O_RDONLY, 577 for O_WRONLY|O_CREAT|O_TRUNC)
; %3: File mode/permissions (Optional, default: 0644o / 420 in decimal)

%macro open_file 2-3 0644o
    mov rax, 257                   ; sys_openat
    mov rdi, -100                  ; AT_FDCWD
    mov rsi, %1                    ; Filename pointer
    mov rdx, %2                    ; Access flags
    mov r10, %3                    ; File permissions mode (e.g., 0644o)
    syscall
%endmacro

; --- Macro: read_file ---
%macro read_file 3
    mov rax, 0                     ; sys_read
    mov rdi, %1                    ; File descriptor
    mov rsi, %2                    ; Buffer pointer
    mov rdx, %3                    ; Bytes count
    syscall
%endmacro

; --- Macro: write_file ---
; Arguments:
; %1: File descriptor
; %2: Pointer to memory buffer
; %3: Bytes count to write
; Output:
; RAX = number of bytes written (or negative error code)
%macro write_file 3
    mov rax, 1                     ; sys_write
    mov rdi, %1                    ; File descriptor
    mov rsi, %2                    ; Buffer pointer
    mov rdx, %3                    ; Bytes count
    syscall
%endmacro

; --- Macro: print_file ---
%macro print_file 2
    mov rax, 1                     ; sys_write
    mov rdi, 1                     ; stdout (file descriptor 1)
    mov rsi, %1                    ; Buffer pointer
    mov rdx, %2                    ; Bytes count
    syscall
%endmacro

; --- Macro: close_file ---
%macro close_file 1
    mov rax, 3                     ; sys_close
    mov rdi, %1                    ; File descriptor
    syscall
%endmacro

%endif