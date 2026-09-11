; ==============================================================================
; File: lib/ast.asm
; Description: AST Definitions and Node Structure
; ==============================================================================

%ifndef AST_ASM
%define AST_ASM

NODE_FUNCTION_CALL  equ 1
NODE_STRING_LITERAL equ 2

struc ASTNode
    .type:     resd 1
    .pad:      resd 1
    .val_ptr:  resq 1
    .val_len:  resq 1
    .arg_ptr:  resq 1
    .next:     resq 1
endstruc

%endif