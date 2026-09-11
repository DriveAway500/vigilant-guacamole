; ==============================================================================
; SYSTEM UTILITY MACROS & IMPLEMENTATION
; ==============================================================================

; -----------------------------------------------------------------------------
; MACROS
; -----------------------------------------------------------------------------

; Usage 1 (Literal string):  println "Hello World"
; Usage 2 (Buffer pointer):  println msg_ptr, msg_len
%macro println 1
    section .rodata
        %%str db %1, 0xA, 0
    section .text
        mov rdi, %%str
        call _fn_println_auto
%endmacro

%macro println 2
    mov rdi, %1
    mov rsi, %2
    call _fn_println
%endmacro

; Usage: input buffer_ptr, buffer_len
; Returns bytes read in RAX
%macro input 2
    mov rdi, %1
    mov rsi, %2
    call _fn_input
%endmacro

; Usage: msleep milliseconds
%macro msleep 1
    mov rdi, %1
    call _fn_msleep
%endmacro

; Usage: nonblock_stdin
%macro nonblock_stdin 0
    call _fn_nonblock_stdin
%endmacro

; Usage: exit [status_code]
%macro exit 0
    mov rax, 60
    xor rdi, rdi
    syscall
%endmacro

%macro exit 1
    mov rax, 60
    mov rdi, %1
    syscall
%endmacro


; -----------------------------------------------------------------------------
; FUNCTION IMPLEMENTATIONS (Guarded against double inclusion)
; -----------------------------------------------------------------------------
%ifndef SYS_IMPL_DONE
%define SYS_IMPL_DONE

section .text

_fn_println:
    mov rdx, rsi        ; count
    mov rsi, rdi        ; buf
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    syscall
    ret

_fn_println_auto:
    mov rsi, rdi        ; save base pointer
.loop:
    cmp byte [rsi], 0
    je .done
    inc rsi
    jmp .loop
.done:
    sub rsi, rdi        ; calculate length
    mov rdx, rsi        ; length
    mov rsi, rdi        ; string pointer
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    syscall
    ret

_fn_input:
    mov rdx, rsi        ; count
    mov rsi, rdi        ; buf
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    syscall
    ret

_fn_nonblock_stdin:
    mov rax, 72         ; sys_fcntl
    mov rdi, 0          ; stdin
    mov rsi, 3          ; F_GETFL
    syscall

    or rax, 2048        ; O_NONBLOCK

    mov rdx, rax        ; new flags
    mov rax, 72         ; sys_fcntl
    mov rdi, 0          ; stdin
    mov rsi, 4          ; F_SETFL
    syscall
    ret

_fn_msleep:
    push rbx            ; preserve callee-saved register

    mov rax, rdi
    xor rdx, rdx
    mov rbx, 1000
    div rbx             ; rax = sec, rdx = remaining ms

    imul rdx, rdx, 1000000 ; ms to ns

    sub rsp, 16         ; allocate struct timespec
    mov [rsp], rax      ; tv_sec
    mov [rsp + 8], rdx  ; tv_nsec

    mov rax, 35         ; sys_nanosleep
    mov rdi, rsp        ; req
    xor rsi, rsi        ; rem (NULL)
    syscall

    add rsp, 16         ; restore stack
    pop rbx             ; restore rbx
    ret

%endif