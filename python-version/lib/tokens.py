from typing import List, NamedTuple, Tuple


class Token(NamedTuple):
    type: str
    value: str


TOKEN_SPECIFICATION: List[Tuple[str, str]] = [
    # Keywords
    ('LET',      r'\blet\b'),
    ('INT_TYPE', r'\bint\b'),
    ('STR_TYPE', r'\bstr\b'),
    ('PRINTLN',  r'\bprintln\b'),
    ('IF',       r'\bif\b'),
    ('ELSE',     r'\belse\b'),
    
    # Literals & Identifiers
    ('NUMBER',   r'\b\d+\b'),
    ('STRING',   r'"[^"]*"'),
    ('IDENT',    r'\b[a-zA-Z_][a-zA-Z0-9_]*\b'),
    
    # Relational Operators (2-char ops before 1-char ops)
    ('EQ',       r'=='),
    ('NEQ',      r'!='),
    ('LE',       r'<='),
    ('GE',       r'>='),
    ('LT',       r'<'),
    ('GT',       r'>'),
    
    # Arithmetic Operators
    ('PLUS',     r'\+'),
    ('MINUS',    r'-'),
    ('MUL',      r'\*'),
    ('DIV',      r'/'),
    
    # Symbols
    ('ASSIGN',   r'='),
    ('LPAREN',   r'\('),
    ('RPAREN',   r'\)'),
    ('LBRACE',   r'\{'),
    ('RBRACE',   r'\}'),
    ('SEMI',     r';'),
    
    # Whitespace and unknown characters
    ('SKIP',     r'[ \t\n]+'),
    ('MISMATCH', r'.'),
]