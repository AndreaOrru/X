"""Command line interface for the X compiler."""

import sys
from ctypes import CFUNCTYPE, c_int

import llvmlite.binding as llvm
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

    llvm.initialize()
    llvm.initialize_native_target()
    llvm.initialize_native_asmprinter()

    target = llvm.Target.from_default_triple()
    target_machine = target.create_target_machine()

    backing_module = llvm.parse_assembly('')
    engine = llvm.create_mcjit_compiler(backing_module, target_machine)

    module = llvm.parse_assembly(code_generator.code)
    module.verify()
    engine.add_module(module)
    engine.finalize_object()

    func_ptr = engine.get_function_address('main')
    c_func = CFUNCTYPE(c_int)(func_ptr)
    print(c_func())
