; ==============================================================================
; File: lib/ast.asm
; Description: AST Definitions and Node Structure
; ==============================================================================

%ifndef AST_ASM
%define AST_ASM

; Node Types
NODE_FUNCTION_CALL  equ 1
NODE_STRING_LITERAL equ 2
NODE_VAR_DECL       equ 3
NODE_INT_LITERAL    equ 4
NODE_IDENTIFIER     equ 5

; Primitive Types
TYPE_INT            equ 1
TYPE_STR            equ 2

struc ASTNode
    .type:     resd 1
    .pad:      resq 1      ; was resd 1 — widen to match qword accesses
    .val_ptr:  resq 1
    .val_len:  resq 1
    .arg_ptr:  resq 1
    .next:     resq 1
endstruc

%endif