from typing import Dict, List
from lib import (
    HEADER_DATA_SECTION,
    HEADER_TEXT_SECTION,
    FOOTER_EXIT,
    ASM_PRINT_INT_HELPER,
    asm_println,
    asm_data_string,
    asm_data_int,
    asm_data_var_string,
    asm_print_var_str,
)
from parser import ASTNode, PrintlnNode, VarDeclNode


class CodeGenerator:
    """AST Visitor that generates NASM x86_64 assembly code."""

    def __init__(self):
        self.data_section: List[str] = []
        self.text_section: List[str] = []
        self.str_count = 0
        self.symbol_table: Dict[str, str] = {}  # Symbol table mapping var_name -> var_type
        self.needs_int_helper = False

    def generate(self, ast: List[ASTNode]) -> str:
        """Entry point to process AST nodes and return assembly output."""
        for node in ast:
            self.visit(node)

        return self._build_assembly()

    def visit(self, node: ASTNode) -> None:
        """Dynamic dispatch mechanism to find the corresponding visitor method."""
        method_name = f"visit_{type(node).__name__}"
        visitor = getattr(self, method_name, self.generic_visit)
        visitor(node)

    def generic_visit(self, node: ASTNode) -> None:
        raise NotImplementedError(f"No visit_{type(node).__name__} method defined.")

    # -------------------------------------------------------------------------
    # Node Visitors (Add new node code-generators below)
    # -------------------------------------------------------------------------

    def visit_PrintlnNode(self, node: PrintlnNode) -> None:
        """Handles code generation for PrintlnNode (string literal or variable)."""
        if not node.is_var:
            # Direct string literal handling
            label_msg = f"msg_{self.str_count}"
            label_len = f"len_{self.str_count}"
            self.str_count += 1

            self.data_section.append(asm_data_string(label_msg, label_len, node.value))
            self.text_section.append(asm_println(label_msg, label_len, node.value))
        else:
            # Variable reference printing
            var_name = node.value
            if var_name not in self.symbol_table:
                raise NameError(f"Variable '{var_name}' is not defined.")

            var_type = self.symbol_table[var_name]
            if var_type == "str":
                self.text_section.append(asm_print_var_str(var_name))
            elif var_type == "int":
                self.needs_int_helper = True
                self.text_section.extend([
                    f"    ; println({var_name}) [int]",
                    f"    mov rax, [var_{var_name}]",
                    f"    call print_int_var",
                ])
            else:
                raise TypeError(f"Cannot print variable '{var_name}' of type '{var_type}'")

    def visit_VarDeclNode(self, node: VarDeclNode) -> None:
        """Handles code generation for VarDeclNode."""
        self.symbol_table[node.name] = node.var_type

        if node.var_type == "int":
            try:
                val = int(node.value)
            except ValueError:
                raise ValueError(
                    f"Invalid integer literal for variable '{node.name}': {node.value}"
                )

            self.data_section.append(asm_data_int(node.name, val))

        elif node.var_type == "str":
            self.data_section.append(asm_data_var_string(node.name, node.value))

        else:
            raise NotImplementedError(f"Unsupported variable type: '{node.var_type}'")

    def _build_assembly(self) -> str:
        """Combines sections into a single NASM source code."""
        if self.needs_int_helper:
            self.data_section.append("    int_buffer resb 32")
            self.data_section.append("    int_buffer_end equ $ - 1")

        data_block = (
            (HEADER_DATA_SECTION + "\n".join(self.data_section) + "\n")
            if self.data_section
            else ""
        )
        text_block = (
            HEADER_TEXT_SECTION + "\n".join(self.text_section) + "\n\n" + FOOTER_EXIT
        )

        if self.needs_int_helper:
            text_block += ASM_PRINT_INT_HELPER

        return data_block + text_block
