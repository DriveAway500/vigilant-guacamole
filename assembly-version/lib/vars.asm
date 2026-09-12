; lib/vars.asm - Typed Variables Abstraction
; Allows declaring, reading, and writing variables specifying their type,
; using direct type names (int, bool, str, etc).
; Independent of the arena allocator (mem.asm).

; Supported types:
;   byte  -> 8 bits
;   word  -> 16 bits
;   int   -> 32 bits
;   long  -> 64 bits
;   bool  -> 8 bits (0/1)
;   ptr   -> 64 bits (address)
;   str   -> string (bytes + pointer)

; ------------------------------------------------------------------------------
; var_decl name, type, [initial_value]
; Usage inside section .data
; Ex: var_decl counter, int, 0
; Ex: var_decl message, str, "hello world"
; ------------------------------------------------------------------------------
%macro var_decl 2-3 0
    %ifidn %2, byte
        %1: db %3
    %elifidn %2, bool
        %1: db %3
    %elifidn %2, word
        %1: dw %3
    %elifidn %2, int
        %1: dd %3
    %elifidn %2, long
        %1: dq %3
    %elifidn %2, ptr
        %1: dq %3
    %elifidn %2, str
        %1_data: db %3, 0
        %1: dq %1_data
    %else
        %error "var_decl: invalid type"
    %endif
%endmacro

; ------------------------------------------------------------------------------
; var_set var, type, value_or_register
; Writes respecting the size of the type.
; The register/immediate must be compatible with the type size
; (ex: int -> eax, long -> rax, word -> ax, byte/bool -> al)
; Ex: var_set counter, int, eax
; ------------------------------------------------------------------------------
%macro var_set 3
    %ifidn %2, byte
        mov byte [%1], %3
    %elifidn %2, bool
        mov byte [%1], %3
    %elifidn %2, word
        mov word [%1], %3
    %elifidn %2, int
        mov dword [%1], %3
    %elifidn %2, long
        mov qword [%1], %3
    %elifidn %2, ptr
        mov qword [%1], %3
    %elifidn %2, str
        mov qword [%1], %3   ; %3 must be an address (label or register)
    %else
        %error "var_set: invalid type"
    %endif
%endmacro

; ------------------------------------------------------------------------------
; var_get dest_reg, var, type
; Reads into a register, respecting the type size.
; Uses movzx (zero-extend) for byte/bool/word.
; Ex: var_get eax, counter, int
; Ex: var_get rsi, message, str   ; rsi receives the pointer to the string
; ------------------------------------------------------------------------------
%macro var_get 3
    %ifidn %3, byte
        movzx %1, byte [%2]
    %elifidn %3, bool
        movzx %1, byte [%2]
    %elifidn %3, word
        movzx %1, word [%2]
    %elifidn %3, int
        mov %1, dword [%2]
    %elifidn %3, long
        mov %1, qword [%2]
    %elifidn %3, ptr
        mov %1, qword [%2]
    %elifidn %3, str
        mov %1, qword [%2]
    %else
        %error "var_get: invalid type"
    %endif
%endmacro

; ==============================================================================
; Control Flow Abstraction
; Allows writing entire modules (ex: parser.asm) without using idiomatic asm
; instructions directly (mov, lea, push, pop, call, test, jz/jnz, ret).
; Everything is expressed through these macros.
; ==============================================================================

; ------------------------------------------------------------------------------
; var_move dest, src
; Moves a value between registers/memory. Replaces "mov".
; Ex: var_move rax, r14
; ------------------------------------------------------------------------------
%macro var_move 2
    mov %1, %2
%endmacro

; ------------------------------------------------------------------------------
; var_addr reg, [address]
; Loads an effective address into a register. Replaces "lea".
; Ex: var_addr rbx, [r12 + 9]
; ------------------------------------------------------------------------------
%macro var_addr 2
    lea %1, %2
%endmacro

; ------------------------------------------------------------------------------
; var_enter reg1, reg2, ...
; Saves registers on the stack (function prologue). Replaces sequential "push".
; Ex: var_enter r12, r13, r14
; ------------------------------------------------------------------------------
%macro var_enter 1-*
    %rep %0
        push %1
        %rotate 1
    %endrep
%endmacro

; ------------------------------------------------------------------------------
; var_leave reg1, reg2, ...
; Restores registers from the stack (function epilogue). Replaces sequential "pop".
; IMPORTANT: pass registers in reverse order of var_enter.
; Ex: var_enter r12, r13, r14  ->  var_leave r14, r13, r12
; ------------------------------------------------------------------------------
%macro var_leave 1-*
    %rep %0
        pop %1
        %rotate 1
    %endrep
%endmacro

; ------------------------------------------------------------------------------
; func_call0 function
; Calls a function with no arguments. Replaces "call".
; ------------------------------------------------------------------------------
%macro func_call0 1
    call %1
%endmacro

; ------------------------------------------------------------------------------
; func_call1 function, arg1
; Calls a function with 1 argument (RDI). Replaces "mov rdi,.. / call".
; ------------------------------------------------------------------------------
%macro func_call1 2
    mov rdi, %2
    call %1
%endmacro

; ------------------------------------------------------------------------------
; func_call2 function, arg1, arg2
; Calls a function with 2 arguments (RDI, RSI). Replaces "mov/mov/call".
; Ex: func_call2 parse_buffer, buf_ptr, buf_size
; ------------------------------------------------------------------------------
%macro func_call2 3
    mov rdi, %2
    mov rsi, %3
    call %1
%endmacro

; ------------------------------------------------------------------------------
; func_call2addr function, label, arg2
; Same as func_call2, but the 1st argument is the ADDRESS of a label (uses lea).
; Ex: func_call2addr arena_alloc, parser_arena, ASTNode_size
; ------------------------------------------------------------------------------
%macro func_call2addr 3
    lea rdi, [%2]
    mov rsi, %3
    call %1
%endmacro

; ------------------------------------------------------------------------------
; func_result reg
; Captures the return value of a call (RAX) into another register.
; Replaces "mov reg, rax".
; ------------------------------------------------------------------------------
%macro func_result 1
    mov %1, rax
%endmacro

; ------------------------------------------------------------------------------
; var_if_zero reg, label
; Jumps to label if reg == 0. Replaces "test reg,reg / jz label".
; ------------------------------------------------------------------------------
%macro var_if_zero 2
    test %1, %1
    jz %2
%endmacro

; ------------------------------------------------------------------------------
; var_if_not_zero reg, label
; Jumps to label if reg != 0. Replaces "test reg,reg / jnz label".
; ------------------------------------------------------------------------------
%macro var_if_not_zero 2
    test %1, %1
    jnz %2
%endmacro

; ------------------------------------------------------------------------------
; var_return [reg]
; Ends the function. If reg is provided, executes "mov rax, reg" before "ret".
; Ex: var_return r14   ; equivalent to "mov rax, r14 / ret"
; Ex: var_return       ; equivalent to just "ret"
; ------------------------------------------------------------------------------
%macro var_return 0-1
    %if %0 = 1
        mov rax, %1
    %endif
    ret
%endmacro