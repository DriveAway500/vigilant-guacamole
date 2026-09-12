"""NASM x86_64 Linux assembly templates."""

HEADER_DATA_SECTION = "section .data\n"
HEADER_TEXT_SECTION = "\nsection .text\n    global _start\n\n_start:\n"

FOOTER_EXIT = """    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall
"""

def asm_println(label_msg: str, label_len: str, text: str) -> str:
    return f"""    ; println("{text}")
    mov rax, 1
    mov rdi, 1
    mov rsi, {label_msg}
    mov rdx, {label_len}
    syscall"""

def asm_data_string(label_msg: str, label_len: str, text: str) -> str:
    return f'    {label_msg} db "{text}", 10\n    {label_len} equ $ - {label_msg}'

def asm_data_int(var_name: str, value: int) -> str:
    return f'    var_{var_name} dq {value}'

def asm_data_var_string(var_name: str, text: str) -> str:
    # Retains both raw string label and length label for sys_write
    return f'    var_{var_name} db "{text}", 10\n    len_var_{var_name} equ $ - var_{var_name}'

# Template for printing a named string variable
def asm_print_var_str(var_name: str) -> str:
    return f"""    ; println({var_name}) [str]
    mov rax, 1
    mov rdi, 1
    mov rsi, var_{var_name}
    mov rdx, len_var_{var_name}
    syscall"""

# Standard integer printing routine helper (writes to stdout via buffer)
ASM_PRINT_INT_HELPER = """
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
"""