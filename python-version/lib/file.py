import os

def write_file(filepath: str, content: str) -> None:
    """Writes content to a file, creating parent directories if necessary."""
    output_dir = os.path.dirname(filepath)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)


def read_file(filepath: str) -> str:
    """Reads and returns the content of a file given its path."""
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Source file not found: {filepath}")

    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()