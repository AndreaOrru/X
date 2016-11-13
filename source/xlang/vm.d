module xlang.vm;

import xlang.compiler;
import std.array;


long[] stack;

long run(in long[] bytecode)
{
    for (int i = 0; i < bytecode.length; i++)
        final switch (bytecode[i])
        {
            case Op.add:      operation!"+"; break;
            case Op.subtract: operation!"-"; break;
            case Op.multiply: operation!"*"; break;
            case Op.divide:   operation!"/"; break;
            case Op.integer:
                stack ~= bytecode[++i];
                break;
        }

    return stack[0];
}

private void operation(string op)()
{
    long temp = stack.back; stack.popBack();
    mixin("stack.back = temp " ~ op ~ " stack.back;");
}
