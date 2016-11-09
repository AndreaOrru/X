"""Command line interface for the X compiler."""

import sys

from antlr4 import CommonTokenStream
from antlr4 import FileStream

from xlang.antlr.XLexer import XLexer
from xlang.antlr.XParser import XParser
from xlang.code_generator import CodeGenerator


def main():
    """Entry point for the CLI."""

    # Tokenize the input:
    file_stream = FileStream(sys.argv[1])   # FIXME: use argparse/click.
    lexer = XLexer(file_stream)
    token_stream = CommonTokenStream(lexer)

    # Parse the program:
    parser = XParser(token_stream)
    tree = parser.program()

    # Compile the code:
    code_generator = CodeGenerator()
    code_generator.visit(tree)
    print(code_generator.code)

    # TODO: generate binary.
