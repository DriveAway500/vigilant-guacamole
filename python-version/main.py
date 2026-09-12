import sys
from cli import parse_args
from lib import write_file, read_file
from parser import lexer, Parser
from codegen import CodeGenerator


class CompilerPipeline:
    """Encapsulates the full compilation flow from source file to output assembly."""

    def __init__(self, source_path: str, output_path: str = "output.asm"):
        self.source_path = source_path
        self.output_path = output_path
        self.codegen = CodeGenerator()

    def compile(self) -> None:
        """Executes the pipeline: Read -> Lex -> Parse -> Codegen -> Write."""
        source_code = read_file(self.source_path)
        tokens = lexer(source_code)
        
        parser = Parser(tokens)
        ast = parser.parse()

        assembly_code = self.codegen.generate(ast)
        write_file(self.output_path, assembly_code)


def main() -> None:
    try:
        args = parse_args()
        pipeline = CompilerPipeline(
            source_path=args.source_path,
            output_path=args.output_path
        )
        pipeline.compile()
        print(f"Successfully compiled '{args.source_path}' to '{args.output_path}'")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
