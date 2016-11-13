module xlang.compiler;

import xlang.parser;
import pegged.grammar;
import std.conv;


enum Op : long { add, subtract, multiply, divide, integer }

private long[] result;

long[] bytecode(in string source)
{
    result = result.init;

    compile(X(source));

    return result;
}

private void compile(in ParseTree[] ps)
{
    foreach (p; ps)
        compile(p);
}

private void compile(in ParseTree p)
{
    switch (p.name)
    {
        case "X.Addition":       operation!(Op.add)(p);      break;
        case "X.Subtraction":    operation!(Op.subtract)(p); break;
        case "X.Multiplication": operation!(Op.multiply)(p); break;
        case "X.Division":       operation!(Op.divide)(p);   break;

        case "X.Integer": integer(p); break;

        default:
            compile(p.children);
            break;
    }
}

private void operation(Op op)(in ParseTree p)
{
    compile(p.children[0]);
    result ~= op;
}

private void integer(in ParseTree p)
{
    result ~= Op.integer;
    result ~= to!long(p.matches[0]);
}
