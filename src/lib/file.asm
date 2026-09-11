; ==============================================================================
; File: lib/file.asm
; Description: Macros for Linux x86_64 file operations and standard I/O
; ==============================================================================

; --- Macro: open_file ---
; Arguments:
; %1: Pointer to filename (null-terminated)
; %2: Flags (e.g., 0 for O_RDONLY)
; Output:
; RAX = file descriptor (or negative error code)
%macro open_file 2
    mov rax, 257                   ; sys_openat
    mov rdi, -100                  ; AT_FDCWD (current directory)
    mov rsi, %1                    ; Filename pointer
    mov rdx, %2                    ; Access flags
    mov r10, 0                     ; Mode
    syscall
%endmacro

; --- Macro: read_file ---
; Arguments:
; %1: File descriptor
; %2: Pointer to memory buffer
; %3: Maximum bytes to read
; Output:
; RAX = number of bytes read (or negative error code)
%macro read_file 3
    mov rax, 0                     ; sys_read
    mov rdi, %1                    ; File descriptor
    mov rsi, %2                    ; Buffer pointer
    mov rdx, %3                    ; Bytes count
    syscall
%endmacro

; --- Macro: print_file ---
; Arguments:
; %1: Pointer to memory buffer
; %2: Number of bytes to write
; Output:
; RAX = number of bytes written
%macro print_file 2
    mov rax, 1                     ; sys_write
    mov rdi, 1                     ; stdout (file descriptor 1)
    mov rsi, %1                    ; Buffer pointer
    mov rdx, %2                    ; Bytes count
    syscall
%endmacro

; --- Macro: close_file ---
; Arguments:
; %1: File descriptor
%macro close_file 1
    mov rax, 3                     ; sys_close
    mov rdi, %1                    ; File descriptor
    syscall
%endmacro