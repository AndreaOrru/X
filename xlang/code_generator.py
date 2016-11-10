# pylint: disable=missing-docstring

from llvmlite import ir

from xlang.antlr.XVisitor import XVisitor


class SymbolTable:
    def __init__(self):
        self._symbols = [dict()]

    def push_frame(self, symbols=None):
        self._symbols.append(symbols or dict())

    def pop_frame(self):
        self._symbols.pop()

    def resolve(self, name):
        for frame in reversed(self._symbols):
            try:
                return frame[name]
            except KeyError:
                pass
        raise KeyError

    def bind(self, name, pointer):
        self._symbols[-1][name] = pointer


class CodeGenerator(XVisitor):
    types = {
        'Void': ir.VoidType(),
        'Int':  ir.IntType(32),
    }

    def __init__(self):
        self._module = ir.Module()
        self._symbols = SymbolTable()
        self._func = None     # Current function.
        self._builder = None  # LLVM IR builder.

    @property
    def code(self):
        return str(self._module)

    def _create_var(self, typ, name, value=None):
        pointer = self._builder.alloca(typ, name=name)
        self._symbols.bind(name, pointer)
        if value is not None:
            self._builder.store(value, pointer)

    def _create_func(self, typ, name):
        self._func = ir.Function(self._module, typ, name=name)
        self._symbols.bind(name, self._func)

    def _create_block(self):
        block = self._func.append_basic_block()
        self._builder = ir.IRBuilder(block)

    def visitVarDecl(self, ctx):
        # ID ':' typ ('=' expr)?
        typ = ctx.typ().getText()
        name = ctx.ID().getText()
        self._create_var(self.types[typ], name)
        if ctx.expr():
            self.visitAssign(ctx)

    def visitFuncDecl(self, ctx):
        # ID '(' params? ')' ('->' typ)? block
        name = ctx.ID().getText()
        try:
            ret_typ = ctx.typ().getText()
        except AttributeError:
            ret_typ = 'Void'    # No type specified, assume Void.

        try:
            params = ctx.params().param()
            param_types = [self.types[x.typ().getText()] for x in params]
            param_names = [x.ID().getText()              for x in params]
        except AttributeError:
            # No parameters:
            param_types = []
            param_names = []

        func_typ = ir.FunctionType(self.types[ret_typ], param_types)
        self._create_func(func_typ, name)

        self._symbols.push_frame()
        self._create_block()

        # Bind parameters inside the function scope:
        for arg, typ, name in zip(self._func.args, param_types, param_names):
            arg.name = name
            self._create_var(typ, name, arg)

        self.visit(ctx.block())
        self._symbols.pop_frame()

        if not self._builder.block.is_terminated and func_typ == self.types['Void']:
            self._builder.ret_void()
        # FIXME: handle the cases in which we are returning inside a void function
        #        or not returning from a non-void function.

    def visitBlock(self, ctx):
        # '{' stmt* '}'
        self._symbols.push_frame()

        for child in ctx.children:
            self.visit(child)

        self._symbols.pop_frame()

    def visitIfElse(self, ctx):
        # 'if' expr block ('else' block)
        with self._builder.if_else(self.visit(ctx.expr())) as (then, otherwise):
            with then:
                self.visit(ctx.block(0))
            with otherwise:
                self.visit(ctx.block(1))
        self._create_block()

    def visitRet(self, ctx):
        # 'return' expr?
        try:
            self._builder.ret(self.visit(ctx.expr()))
        except AttributeError:
            if self._func.return_value.type == self.types['Void']:
                self._builder.ret_void()
            else:
                raise Exception("Function must return a value.")

    def visitAssign(self, ctx):
        # ID '=' expr
        name = ctx.ID().getText()
        try:
            pointer = self._symbols.resolve(name)
            value = self.visit(ctx.expr())
            if pointer.type.pointee != value.type:
                raise Exception("Type mismatch in assignment.")
            return self._builder.store(value, pointer)
        except KeyError:
            raise Exception("Undeclared identifier in assignment.")

    def visitParensExpr(self, ctx):
        # '(' expr ')'
        return self.visit(ctx.expr())

    def visitCallExpr(self, ctx):
        # ID '(' exprList? ')'
        name = ctx.ID().getText()
        try:
            func = self._symbols.resolve(name)
            if not isinstance(func, ir.Function):
                raise Exception("Trying to call non-function.")

            try:
                params = [self.visit(x) for x in ctx.exprList().expr()]
            except AttributeError:
                params = []
            if len(params) != len(func.args):
                raise Exception("Wrong number of parameters in call.")

            for param, arg in zip(params, func.args):
                if param.type != arg.type:
                    raise Exception("Wrong type of parameter.")
            return self._builder.call(func, params)
        except KeyError:
            raise Exception("Undeclared identifier in expression.")

    def visitMinusExpr(self, ctx):
        # '-' expr
        return self._builder.neg(self.visit(ctx.expr()))

    def visitMulDivExpr(self, ctx):
        # expr ('*' | '/') expr
        op = ctx.op.text
        lhs = self.visit(ctx.expr(0))
        rhs = self.visit(ctx.expr(1))
        if op == '*':
            return self._builder.mul(lhs, rhs)
        elif op == '/':
            return self._builder.sdiv(lhs, rhs)

    def visitAddSubExpr(self, ctx):
        # expr ('+' | '-') expr
        op = ctx.op.text
        lhs = self.visit(ctx.expr(0))
        rhs = self.visit(ctx.expr(1))
        if op == '+':
            return self._builder.add(lhs, rhs)
        elif op == '-':
            return self._builder.sub(lhs, rhs)

    def visitRelExpr(self, ctx):
        # expr ('<' | '<= | '==' | '!=' | '>=' | '>') expr
        op = ctx.op.text
        lhs = self.visit(ctx.expr(0))
        rhs = self.visit(ctx.expr(1))
        return self._builder.icmp_signed(op, lhs, rhs)

    def visitIdExpr(self, ctx):
        # ID
        name = ctx.ID().getText()
        try:
            pointer = self._symbols.resolve(name)
            return self._builder.load(pointer)
        except IndexError:
            raise Exception("Undeclared identifier in expression.")

    def visitIntExpr(self, ctx):
        # INT
        integer = ctx.INT().getText()
        return ir.Constant(self.types['Int'], int(integer))
