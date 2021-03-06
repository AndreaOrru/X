# pylint: disable=missing-docstring

from llvmlite import ir

from xlang.antlr.XParser import XParser
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
    def __init__(self):
        self._module = ir.Module()
        self._symbols = SymbolTable()
        self._func = None     # Current function.
        self._builder = None  # LLVM IR builder.

    @property
    def code(self):
        return str(self._module)

    def _create_var(self, typ, name, value=None):
        if self._func is None:
            pointer = ir.GlobalVariable(self._module, typ, name)
            pointer.initializer = value
        else:
            pointer = self._builder.alloca(typ, name=name)
            if value is not None:
                self._builder.store(value, pointer)
        self._symbols.bind(name, pointer)

    def _create_func(self, typ, name):
        self._func = ir.Function(self._module, typ, name=name)
        self._symbols.bind(name, self._func)

    def _create_block(self):
        block = self._func.append_basic_block()
        self._builder = ir.IRBuilder(block)

    def visitVarDecl(self, ctx):
        # ID ':' typ ('=' expr)?
        typ = self.visit(ctx.typ())
        name = ctx.ID().getText()
        if ctx.expr():
            self._create_var(typ, name, self.visit(ctx.expr()))
        else:
            self._create_var(typ, name)

    def visitFuncDecl(self, ctx):
        # ID '(' params? ')' ('->' typ)? block
        name = ctx.ID().getText()
        try:
            ret_typ = self.visit(ctx.typ())
        except AttributeError:
            ret_typ = ir.VoidType()

        try:
            params = ctx.params().param()
            param_types = [self.visit(x.typ()) for x in params]
            param_names = [x.ID().getText()    for x in params]
        except AttributeError:
            # No parameters:
            param_types = []
            param_names = []

        func_typ = ir.FunctionType(ret_typ, param_types)
        self._create_func(func_typ, name)

        self._symbols.push_frame()
        self._create_block()

        # Bind parameters inside the function scope:
        for arg, typ, name in zip(self._func.args, param_types, param_names):
            arg.name = name
            self._create_var(typ, name, arg)

        self.visit(ctx.block())
        self._symbols.pop_frame()

        # FIXME: handle the cases in which we are returning inside a void function
        #        or not returning from a non-void function.
        if not self._builder.block.is_terminated:
            if func_typ == ir.VoidType():
                self._builder.ret_void()
            else:
                self._builder.unreachable()

        self._func = None

    def visitBlock(self, ctx):
        # '{' stmt* '}'
        self._symbols.push_frame()

        for child in ctx.children:
            self.visit(child)

        self._symbols.pop_frame()

    def visitIfElse(self, ctx):
        # 'if' expr blockOrStmt ('else' blockOrStmt)?
        blocks = ctx.blockOrStmt()

        # No else branch:
        if len(blocks) == 1:
            with self._builder.if_then(self.visit(ctx.expr())):
                self.visit(blocks[0])

        # With else branch:
        else:
            with self._builder.if_else(self.visit(ctx.expr())) as (then, otherwise):
                with then:
                    self.visit(blocks[0])
                with otherwise:
                    self.visit(blocks[1])

    def visitWhileLoop(self, ctx):
        while_cond = self._builder.append_basic_block()
        while_body = self._builder.append_basic_block()
        while_end = self._builder.append_basic_block()

        self._builder.branch(while_cond)

        self._builder.position_at_end(while_cond)
        self._builder.cbranch(self.visit(ctx.expr()), while_body, while_end)

        self._builder.position_at_end(while_body)
        self.visit(ctx.blockOrStmt())
        self._builder.branch(while_cond)

        self._builder.position_at_end(while_end)

    def visitRet(self, ctx):
        # 'return' expr?
        try:
            self._builder.ret(self.visit(ctx.expr()))
        except AttributeError:
            if self._func.return_value.type == ir.VoidType():
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

    def visitRefExpr(self, ctx):
        if isinstance(ctx.lValue(), XParser.IdExprContext):
            name = ctx.lValue().getText()
            pointer = self._symbols.resolve(name)
            return pointer
        # FIXME: handle the other cases.

    def visitDerefExpr(self, ctx):
        return self._builder.load(self.visit(ctx.expr()))

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
        return ir.Constant(ir.IntType(32), int(integer))

    def visitIntType(self, ctx):
        return ir.IntType(32)

    def visitPtrType(self, ctx):
        return ir.PointerType(self.visit(ctx.typ()))
