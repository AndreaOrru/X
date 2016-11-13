module xlang.vm;

import xlang.compiler;
import std.array;


long[] stack;
long[] memory;

long run(in long[] bytecode)
{
    for (int i = 0; i < bytecode.length; i++)
        final switch (bytecode[i])
        {
            case Op.add:      operation!"+"; break;
            case Op.subtract: operation!"-"; break;
            case Op.multiply: operation!"*"; break;
            case Op.divide:   operation!"/"; break;

            case Op.load:  load(bytecode[++i]);  break;
            case Op.store: store(bytecode[++i]); break;
            case Op.push:  push(bytecode[++i]);  break;
            case Op.ret:   return stack[0];
        }

    assert(0);
}

private void operation(string op)()
{
    long temp = stack.back; stack.popBack();
    mixin("stack.back = temp " ~ op ~ " stack.back;");
}

private void push(long value)
{
    stack ~= value;
}

private long pop()
{
    long value = stack.back;
    stack.popBack();
    return value;
}

private void load(long symbol)
{
    push(memory[symbol]);
}

private void store(long symbol)
{
    if (symbol >= memory.length)
        memory ~= pop();
    else
        memory[symbol] = pop();
}
