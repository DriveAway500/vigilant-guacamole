import re
from typing import List
from lib import Token, TOKEN_SPECIFICATION


# -------------------------------------------------------------------------
# AST Nodes
# -------------------------------------------------------------------------
class ASTNode:
    pass


class PrintlnNode(ASTNode):
    """AST node representing a println instruction with a string literal or variable."""

    def __init__(self, value: str, is_var: bool = False):
        self.value = value
        self.is_var = is_var

    def __repr__(self):
        return f"PrintlnNode(value={self.value!r}, is_var={self.is_var})"


class VarDeclNode(ASTNode):
    """AST node representing variable declaration (let <type> <var_name> = <val>;)."""

    def __init__(self, var_type: str, name: str, value: str):
        self.var_type = var_type
        self.name = name
        self.value = value

    def __repr__(self):
        return (
            f"VarDeclNode(type={self.var_type!r}, name={self.name!r}, value={self.value!r})"
        )


# -------------------------------------------------------------------------
# Tokenizer (Lexer)
# -------------------------------------------------------------------------
def lexer(code: str) -> List[Token]:
    tok_regex = "|".join(
        f"(?P<{pair[0]}>{pair[1]})" for pair in TOKEN_SPECIFICATION
    )
    tokens = []

    for mo in re.finditer(tok_regex, code):
        kind = mo.lastgroup
        value = mo.group()
        if kind == "SKIP":
            continue
        elif kind == "MISMATCH":
            raise RuntimeError(f"Unexpected character: {value}")

        # Remove quotation marks from string literals
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

    def peek(self) -> Token:
        if self.pos < len(self.tokens):
            return self.tokens[self.pos]
        return Token("EOF", "")

    def consume(self, expected_type: str) -> Token:
        token = self.peek()
        if token.type != expected_type:
            raise SyntaxError(f"Expected {expected_type}, got {token.type}")
        self.pos += 1
        return token

    def parse(self) -> List[ASTNode]:
        ast = []
        while self.peek().type != "EOF":
            current_type = self.peek().type
            if current_type == "PRINTLN":
                ast.append(self.parse_println())
            elif current_type == "LET":
                ast.append(self.parse_var_decl())
            else:
                raise SyntaxError(f"Unexpected token: {self.peek()}")
        return ast

    def parse_println(self) -> PrintlnNode:
        self.consume("PRINTLN")
        self.consume("LPAREN")

        arg_token = self.peek()
        if arg_token.type == "STRING":
            self.consume("STRING")
            is_var = False
        elif arg_token.type == "IDENT":
            self.consume("IDENT")
            is_var = True
        else:
            raise SyntaxError(f"Expected STRING or IDENT, got {arg_token.type}")

        self.consume("RPAREN")
        self.consume("SEMI")
        return PrintlnNode(arg_token.value, is_var=is_var)

    def parse_var_decl(self) -> VarDeclNode:
        self.consume("LET")

        type_token = self.peek()
        if type_token.type not in ("INT_TYPE", "STR_TYPE", "IDENT"):
            raise SyntaxError(f"Expected type identifier, got {type_token.type}")
        self.pos += 1

        name_token = self.consume("IDENT")
        self.consume("ASSIGN")

        val_token = self.peek()
        if val_token.type not in ("STRING", "NUMBER"):
            raise SyntaxError(f"Expected value literal, got {val_token.type}")
        self.pos += 1

        self.consume("SEMI")
        return VarDeclNode(type_token.value, name_token.value, val_token.value)