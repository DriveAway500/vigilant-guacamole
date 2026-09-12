from typing import Dict, List
from lib import (
    HEADER_DATA_SECTION,
    HEADER_BSS_SECTION,
    HEADER_TEXT_SECTION,
    FOOTER_EXIT,
    ASM_PRINT_INT_HELPER,
    asm_println,
    asm_data_string,
    asm_data_int,
    asm_data_bool,
    asm_data_var_string,
    asm_print_var_str,
    asm_push_num,
    asm_push_bool,
    asm_push_var,
    asm_store_var,
    asm_binop,
    asm_cmp_and_jump,
    asm_test_bool_and_jump,
    asm_jump,
    asm_label,
    asm_print_expr_int,
)
from parser import (
    ASTNode,
    PrintlnNode,
    VarDeclNode,
    AssignNode,
    BinaryOpNode,
    NumberNode,
    BoolNode,
    StringNode,
    VarRefNode,
    IfNode,
    WhileNode,
    BlockNode,
)


class CodeGenerator:
    """AST Visitor that generates NASM x86_64 assembly code."""

    def __init__(self):
        self.bss_section: List[str] = []
        self.data_section: List[str] = []
        self.text_section: List[str] = []
        self.str_count = 0
        self.label_count = 0
        self.symbol_table: Dict[str, str] = {}
        self.needs_int_helper = False

    def generate(self, ast: List[ASTNode]) -> str:
        for node in ast:
            self.visit(node)

        return self._build_assembly()

    def visit(self, node: ASTNode):
        method_name = f"visit_{type(node).__name__}"
        visitor = getattr(self, method_name, self.generic_visit)
        return visitor(node)

    def generic_visit(self, node: ASTNode):
        raise NotImplementedError(f"No visit_{type(node).__name__} method defined.")

    # -------------------------------------------------------------------------
    # Expression Visitors
    # -------------------------------------------------------------------------

    def visit_NumberNode(self, node: NumberNode) -> str:
        self.text_section.append(asm_push_num(node.value))
        return "int"

    def visit_BoolNode(self, node: BoolNode) -> str:
        self.text_section.append(asm_push_bool(node.value))
        return "bool"

    def visit_StringNode(self, node: StringNode) -> str:
        return "str"

    def visit_VarRefNode(self, node: VarRefNode) -> str:
        if node.name not in self.symbol_table:
            raise NameError(f"Variable '{node.name}' is not defined.")

        var_type = self.symbol_table[node.name]
        if var_type in ("int", "bool"):
            self.text_section.append(asm_push_var(node.name))

        return var_type

    def visit_BinaryOpNode(self, node: BinaryOpNode) -> str:
        left_type = self.visit(node.left)
        right_type = self.visit(node.right)

        if left_type != "int" or right_type != "int":
            raise TypeError(
                f"Binary operator '{node.op}' unsupported between types '{left_type}' and '{right_type}'."
            )

        if node.op in ("+", "-", "*", "/"):
            self.text_section.append(asm_binop(node.op))
            return "int"
        elif node.op in (">", "<", ">=", "<=", "==", "!="):
            return "bool"
        
        raise ValueError(f"Unsupported binary operator: '{node.op}'")

    # -------------------------------------------------------------------------
    # Statement Visitors
    # -------------------------------------------------------------------------

    def visit_BlockNode(self, node: BlockNode) -> None:
        for stmt in node.statements:
            self.visit(stmt)

    def _generate_condition_check(self, condition_node: ASTNode, false_label: str) -> None:
        if isinstance(condition_node, BinaryOpNode) and condition_node.op in (">", "<", ">=", "<=", "==", "!="):
            self.visit(condition_node.left)
            self.visit(condition_node.right)
            self.text_section.append(asm_cmp_and_jump(condition_node.op, false_label))
        else:
            cond_type = self.visit(condition_node)
            if cond_type != "bool":
                raise TypeError(f"Condition must evaluate to boolean, got '{cond_type}'")
            self.text_section.append(asm_test_bool_and_jump(false_label))

    def visit_IfNode(self, node: IfNode) -> None:
        label_id = self.label_count
        self.label_count += 1

        else_label = f".L_else_{label_id}"
        end_label = f".L_end_if_{label_id}"
        target_label = else_label if node.else_branch else end_label

        self._generate_condition_check(node.condition, target_label)
        self.visit(node.then_branch)

        if node.else_branch:
            self.text_section.append(asm_jump(end_label))
            self.text_section.append(asm_label(else_label))
            self.visit(node.else_branch)

        self.text_section.append(asm_label(end_label))

    def visit_WhileNode(self, node: WhileNode) -> None:
        label_id = self.label_count
        self.label_count += 1

        start_label = f".L_while_start_{label_id}"
        end_label = f".L_while_end_{label_id}"

        self.text_section.append(asm_label(start_label))
        self._generate_condition_check(node.condition, end_label)
        self.visit(node.body)
        self.text_section.append(asm_jump(start_label))
        self.text_section.append(asm_label(end_label))

    def visit_PrintlnNode(self, node: PrintlnNode) -> None:
        if isinstance(node.expression, StringNode):
            label_msg = f"msg_{self.str_count}"
            label_len = f"len_{self.str_count}"
            self.str_count += 1

            self.data_section.append(
                asm_data_string(label_msg, label_len, node.expression.value)
            )
            self.text_section.append(
                asm_println(label_msg, label_len, node.expression.value)
            )

        elif isinstance(node.expression, VarRefNode) and (
            self.symbol_table.get(node.expression.name) == "str"
        ):
            self.text_section.append(asm_print_var_str(node.expression.name))

        else:
            expr_type = self.visit(node.expression)
            if expr_type == "int":
                self.needs_int_helper = True
                self.text_section.append(asm_print_expr_int())
            else:
                raise TypeError(f"Cannot print expression of type '{expr_type}'")

    def visit_VarDeclNode(self, node: VarDeclNode) -> None:
        self.symbol_table[node.name] = node.var_type

        if node.var_type == "int":
            expr_type = self.visit(node.value)
            if expr_type != "int":
                raise TypeError(
                    f"Cannot assign type '{expr_type}' to variable '{node.name}' of type 'int'"
                )
            self.data_section.append(asm_data_int(node.name, 0))
            self.text_section.append(asm_store_var(node.name))

        elif node.var_type == "bool":
            expr_type = self.visit(node.value)
            if expr_type != "bool":
                raise TypeError(
                    f"Cannot assign type '{expr_type}' to variable '{node.name}' of type 'bool'"
                )
            self.data_section.append(asm_data_bool(node.name, False))
            self.text_section.append(asm_store_var(node.name))

        elif node.var_type == "str":
            if isinstance(node.value, StringNode):
                self.data_section.append(
                    asm_data_var_string(node.name, node.value.value)
                )
            else:
                raise TypeError(
                    f"Only direct string literals are supported for string variable '{node.name}'."
                )

        else:
            raise NotImplementedError(f"Unsupported variable type: '{node.var_type}'")

    def visit_AssignNode(self, node: AssignNode) -> None:
        if node.name not in self.symbol_table:
            raise NameError(f"Variable '{node.name}' is not defined.")

        var_type = self.symbol_table[node.name]
        expr_type = self.visit(node.value)

        if var_type != expr_type:
            raise TypeError(
                f"Cannot assign type '{expr_type}' to variable '{node.name}' of type '{var_type}'"
            )

        self.text_section.append(asm_store_var(node.name))

    def _build_assembly(self) -> str:
        if self.needs_int_helper:
            self.bss_section.append("    int_buffer resb 32")

        data_block = (
            (HEADER_DATA_SECTION + "\n".join(self.data_section) + "\n")
            if self.data_section
            else ""
        )
        bss_block = (
            (HEADER_BSS_SECTION + "\n".join(self.bss_section) + "\n")
            if self.bss_section
            else ""
        )
        text_block = (
            HEADER_TEXT_SECTION + "\n".join(self.text_section) + "\n\n" + FOOTER_EXIT
        )

        if self.needs_int_helper:
            text_block += ASM_PRINT_INT_HELPER

        return data_block + bss_block + text_block