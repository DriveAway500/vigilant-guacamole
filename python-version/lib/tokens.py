from typing import List, NamedTuple, Tuple

class Token(NamedTuple):
    type: str
    value: str

# Standard token rules: (TOKEN_TYPE, REGEX_PATTERN)
TOKEN_SPECIFICATION: List[Tuple[str, str]] = [
    # Keywords
    ('LET',      r'\blet\b'),
    ('INT_TYPE', r'\bint\b'),
    ('PRINTLN',  r'\bprintln\b'),
    
    # Literals & Identifiers
    ('NUMBER',   r'\b\d+\b'),
    ('STRING',   r'"[^"]*"'),
    ('IDENT',    r'\b[a-zA-Z_][a-zA-Z0-9_]*\b'),
    
    # Operators & Symbols
    ('ASSIGN',   r'='),
    ('LPAREN',   r'\('),
    ('RPAREN',   r'\)'),
    ('SEMI',     r';'),
    
    # Whitespace and unknown characters
    ('SKIP',     r'[ \t\n]+'),
    ('MISMATCH', r'.'),
]