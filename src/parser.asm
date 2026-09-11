; parser.asm - Parser Module (Multiple Statements Support)
default rel

%include "lib/mem.asm"
%include "lib/ast.asm"

section .bss
    parser_arena: resb Arena_size

section .text
    global parse_buffer

%macro PARSE_BUFFER 2
    mov rdi, %1          ; 1st argument: buffer pointer
    mov rsi, %2          ; 2nd argument: buffer size
    call parse_buffer    ; Returns head ASTNode pointer in RAX
%endmacro

parse_buffer:
    ; Input:  RDI = buffer_ptr, RSI = buffer_size
    ; Output: RAX = pointer to head ASTNode

    push r12
    push r13
    push r14
    push r15
    push rbx

    mov r12, rdi         ; R12 = Current buffer position
    mov r13, rsi         ; R13 = Remaining buffer bytes

    ; --- 1. Init Arena ---
    mov rax, [parser_arena + Arena.base]
    test rax, rax
    jnz .parse_init_vars

    lea rdi, [parser_arena]
    mov rsi, 65536       ; 64KB capacity
    call arena_init

.parse_init_vars:
    xor r14, r14         ; R14 = Head of AST list
    xor r15, r15         ; R15 = Tail of AST list (for appending .next)

.parse_loop:
    cmp r13, 10          ; Minimum bytes needed for `println("")`
    jl .parse_done

    ; Check if buffer starts with "println(" (4 bytes "prin" + 2 bytes "tl" + "n(")
    cmp dword [r12], "prin"
    jne .advance_char
    cmp word [r12 + 4], "tl"
    jne .advance_char
    cmp word [r12 + 6], "n("
    jne .advance_char
    cmp byte [r12 + 8], '"'
    jne .advance_char

    ; --- 2. Allocate Call Node ---
    lea rdi, [parser_arena]
    mov rsi, ASTNode_size
    call arena_alloc
    mov rbx, rax         ; RBX = New Call ASTNode

    ; Clear node memory (Crucial to zero .next!)
    mov qword [rbx + ASTNode.type], NODE_FUNCTION_CALL
    mov qword [rbx + ASTNode.val_ptr], 0
    mov qword [rbx + ASTNode.val_len], 0
    mov qword [rbx + ASTNode.arg_ptr], 0
    mov qword [rbx + ASTNode.next], 0

    ; --- 3. Allocate String Argument Node ---
    lea rdi, [parser_arena]
    mov rsi, ASTNode_size
    call arena_alloc     ; RAX = New String ASTNode

    mov qword [rax + ASTNode.type], NODE_STRING_LITERAL
    mov qword [rax + ASTNode.arg_ptr], 0
    mov qword [rax + ASTNode.next], 0

    ; Set string start past `println("`
    lea r8, [r12 + 9]
    mov qword [rax + ASTNode.val_ptr], r8

    ; --- 4. Scan String Length until '"' ---
    xor rcx, rcx
.scan_str:
    cmp rcx, r13
    jge .str_done
    movzx edx, byte [r8 + rcx]
    cmp dl, '"'
    je .str_done
    cmp dl, 10           ; Stop on newline safety check
    je .str_done
    inc rcx
    jmp .scan_str

.str_done:
    mov qword [rax + ASTNode.val_len], rcx
    mov qword [rbx + ASTNode.arg_ptr], rax ; Link argument to call node

    ; --- 5. Append to AST Linked List ---
    test r14, r14
    jnz .append_node
    mov r14, rbx         ; If head is null, set head = rbx
    jmp .set_tail

.append_node:
    mov qword [r15 + ASTNode.next], rbx ; tail.next = rbx

.set_tail:
    mov r15, rbx         ; tail = rbx

    ; Advance buffer past string + closing `")`
    add rcx, 11          ; Length of `println("` (9) + `")` (2)
    sub r13, rcx
    add r12, rcx
    jmp .parse_loop

.advance_char:
    inc r12
    dec r13
    jmp .parse_loop

.parse_done:
    mov rax, r14          ; Return head ASTNode in RAX

    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret