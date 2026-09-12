import re
from typing import List, Optional
from lib import Token, TOKEN_SPECIFICATION


# -------------------------------------------------------------------------
# AST Nodes
# -------------------------------------------------------------------------
class ASTNode:
    pass


class NumberNode(ASTNode):
    def __init__(self, value: int):
        self.value = value

    def __repr__(self):
        return f"NumberNode(value={self.value})"


class BoolNode(ASTNode):
    def __init__(self, value: bool):
        self.value = value

    def __repr__(self):
        return f"BoolNode(value={self.value})"


class StringNode(ASTNode):
    def __init__(self, value: str):
        self.value = value

    def __repr__(self):
        return f"StringNode(value={self.value!r})"


class VarRefNode(ASTNode):
    def __init__(self, name: str):
        self.name = name

    def __repr__(self):
        return f"VarRefNode(name={self.name!r})"


class BinaryOpNode(ASTNode):
    def __init__(self, left: ASTNode, op: str, right: ASTNode):
        self.left = left
        self.op = op
        self.right = right

    def __repr__(self):
        return f"BinaryOpNode(left={self.left}, op={self.op!r}, right={self.right})"


class PrintlnNode(ASTNode):
    def __init__(self, expression: ASTNode):
        self.expression = expression

    def __repr__(self):
        return f"PrintlnNode(expression={self.expression})"


class VarDeclNode(ASTNode):
    def __init__(self, var_type: str, name: str, value: ASTNode):
        self.var_type = var_type
        self.name = name
        self.value = value

    def __repr__(self):
        return f"VarDeclNode(type={self.var_type!r}, name={self.name!r}, value={self.value})"


class AssignNode(ASTNode):
    def __init__(self, name: str, value: ASTNode):
        self.name = name
        self.value = value

    def __repr__(self):
        return f"AssignNode(name={self.name!r}, value={self.value})"


class BlockNode(ASTNode):
    def __init__(self, statements: List[ASTNode]):
        self.statements = statements

    def __repr__(self):
        return f"BlockNode(statements={self.statements})"


class IfNode(ASTNode):
    def __init__(self, condition: ASTNode, then_branch: BlockNode, else_branch: Optional[BlockNode] = None):
        self.condition = condition
        self.then_branch = then_branch
        self.else_branch = else_branch

    def __repr__(self):
        return f"IfNode(condition={self.condition}, then={self.then_branch}, else={self.else_branch})"


class WhileNode(ASTNode):
    def __init__(self, condition: ASTNode, body: BlockNode):
        self.condition = condition
        self.body = body

    def __repr__(self):
        return f"WhileNode(condition={self.condition}, body={self.body})"


# -------------------------------------------------------------------------
# Tokenizer (Lexer)
# -------------------------------------------------------------------------
def lexer(code: str) -> List[Token]:
    tok_regex = "|".join(f"(?P<{pair[0]}>{pair[1]})" for pair in TOKEN_SPECIFICATION)
    tokens = []

    for mo in re.finditer(tok_regex, code):
        kind = mo.lastgroup
        value = mo.group()
        if kind == "SKIP":
            continue
        elif kind == "MISMATCH":
            raise RuntimeError(f"Unexpected character: {value}")

        if kind == "STRING":
            value = value[1:-1]

        tokens.append(Token(kind, value))
    return tokens


# -------------------------------------------------------------------------
# Parser
# -------------------------------------------------------------------------
class Parser:
    def __init__(self, tokens: List[Token]):
        self.tokens = tokens
        self.pos = 0

    def peek(self, offset: int = 0) -> Token:
        idx = self.pos + offset
        if idx < len(self.tokens):
            return self.tokens[idx]
        return Token("EOF", "")

    def consume(self, expected_type: str) -> Token:
        token = self.peek()
        if token.type != expected_type:
            raise SyntaxError(f"Expected {expected_type}, got {token.type}")
        self.pos += 1
        return token

    def parse(self) -> List[ASTNode]:
        statements = []
        while self.peek().type != "EOF":
            statements.append(self.parse_statement())
        return statements

    def parse_statement(self) -> ASTNode:
        current_type = self.peek().type
        if current_type == "PRINTLN":
            return self.parse_println()
        elif current_type == "LET":
            return self.parse_var_decl()
        elif current_type == "IF":
            return self.parse_if()
        elif current_type == "WHILE":
            return self.parse_while()
        elif current_type == "IDENT" and self.peek(1).type == "ASSIGN":
            return self.parse_assign()
        else:
            raise SyntaxError(f"Unexpected token: {self.peek()}")

    def parse_block(self) -> BlockNode:
        self.consume("LBRACE")
        statements = []
        while self.peek().type != "RBRACE" and self.peek().type != "EOF":
            statements.append(self.parse_statement())
        self.consume("RBRACE")
        return BlockNode(statements)

    def parse_if(self) -> IfNode:
        self.consume("IF")
        self.consume("LPAREN")
        condition = self.parse_expr()
        self.consume("RPAREN")

        then_branch = self.parse_block()
        else_branch = None

        if self.peek().type == "ELSE":
            self.consume("ELSE")
            else_branch = self.parse_block()

        return IfNode(condition, then_branch, else_branch)

    def parse_while(self) -> WhileNode:
        self.consume("WHILE")
        self.consume("LPAREN")
        condition = self.parse_expr()
        self.consume("RPAREN")

        body = self.parse_block()
        return WhileNode(condition, body)

    def parse_assign(self) -> AssignNode:
        name_token = self.consume("IDENT")
        self.consume("ASSIGN")
        value_expr = self.parse_expr()
        self.consume("SEMI")
        return AssignNode(name_token.value, value_expr)

    def parse_primary(self) -> ASTNode:
        token = self.peek()

        if token.type == "NUMBER":
            self.consume("NUMBER")
            return NumberNode(int(token.value))
        elif token.type == "TRUE":
            self.consume("TRUE")
            return BoolNode(True)
        elif token.type == "FALSE":
            self.consume("FALSE")
            return BoolNode(False)
        elif token.type == "STRING":
            self.consume("STRING")
            return StringNode(token.value)
        elif token.type == "IDENT":
            self.consume("IDENT")
            return VarRefNode(token.value)
        elif token.type == "LPAREN":
            self.consume("LPAREN")
            expr = self.parse_expr()
            self.consume("RPAREN")
            return expr

        raise SyntaxError(f"Unexpected token in expression: {token}")

    def parse_term(self) -> ASTNode:
        left = self.parse_primary()

        while self.peek().type in ("MUL", "DIV"):
            op_token = self.consume(self.peek().type)
            right = self.parse_primary()
            left = BinaryOpNode(left, op_token.value, right)

        return left

    def parse_arithmetic(self) -> ASTNode:
        left = self.parse_term()

        while self.peek().type in ("PLUS", "MINUS"):
            op_token = self.consume(self.peek().type)
            right = self.parse_term()
            left = BinaryOpNode(left, op_token.value, right)

        return left

    def parse_expr(self) -> ASTNode:
        left = self.parse_arithmetic()

        rel_ops = ("EQ", "NEQ", "LT", "GT", "LE", "GE")
        if self.peek().type in rel_ops:
            op_token = self.consume(self.peek().type)
            right = self.parse_arithmetic()
            left = BinaryOpNode(left, op_token.value, right)

        return left

    def parse_println(self) -> PrintlnNode:
        self.consume("PRINTLN")
        self.consume("LPAREN")
        expr = self.parse_expr()
        self.consume("RPAREN")
        self.consume("SEMI")
        return PrintlnNode(expr)

    def parse_var_decl(self) -> VarDeclNode:
        self.consume("LET")

        type_token = self.peek()
        if type_token.type not in ("INT_TYPE", "STR_TYPE", "BOOL_TYPE", "IDENT"):
            raise SyntaxError(f"Expected type identifier, got {type_token.type}")
        self.pos += 1

        name_token = self.consume("IDENT")
        self.consume("ASSIGN")
        value_expr = self.parse_expr()
        self.consume("SEMI")

        return VarDeclNode(type_token.value, name_token.value, value_expr)