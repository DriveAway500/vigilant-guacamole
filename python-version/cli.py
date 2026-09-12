import argparse
import sys
from typing import NamedTuple


class CLIArgs(NamedTuple):
    source_path: str
    output_path: str


def parse_args() -> CLIArgs:
    """Parses command line arguments for the compiler interface."""
    parser = argparse.ArgumentParser(
        description="Simple NASM x86_64 compiler pipeline."
    )
    
    parser.add_argument(
        "source",
        type=str,
        help="Path to the source file to compile"
    )
    
    parser.add_argument(
        "-o", "--output",
        type=str,
        default="output.asm",
        help="Output assembly file path (default: output.asm)"
    )

    args = parser.parse_args()
    return CLIArgs(source_path=args.source, output_path=args.output)