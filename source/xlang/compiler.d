module xlang.compiler;

import xlang.parser;
import pegged.grammar;
import std.conv;


enum Op : long { add, sub, mul, div, neg, number }

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
        case "X.Add":    operation!(Op.add)(p); break;
        case "X.Sub":    operation!(Op.sub)(p); break;
        case "X.Mul":    operation!(Op.mul)(p); break;
        case "X.Div":    operation!(Op.div)(p); break;
        case "X.Neg":    operation!(Op.neg)(p); break;
        case "X.Number": number(p); break;
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

private void number(in ParseTree p)
{
    result ~= Op.number;
    result ~= to!long(p.matches[0]);
}
