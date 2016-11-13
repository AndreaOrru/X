module xlang.compiler;

import xlang.parser;
import pegged.grammar;
import std.conv;
import std.stdio;


enum Op : long { add, subtract, multiply, divide, push, load, store, ret }

long symbolId = 0;
private long[string] symbolTable;
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
        case "X.AssignmentStatement": assignmentStatement(p); break;
        case "X.ReturnStatement":     returnStatement(p);     break;

        case "X.Addition":       operation!(Op.add)(p);      break;
        case "X.Subtraction":    operation!(Op.subtract)(p); break;
        case "X.Multiplication": operation!(Op.multiply)(p); break;
        case "X.Division":       operation!(Op.divide)(p);   break;

        case "X.Identifier": identifier(p); break;
        case "X.Integer":    integer(p);    break;

        default:
            compile(p.children);
            break;
    }
}

private void assignmentStatement(in ParseTree p)
{
    compile(p.children[1]);

    string name = p.children[0].matches[0];

    result ~= Op.store;

    if (auto symbol = name in symbolTable)
        result ~= *symbol;
    else
        result ~= symbolTable[name] = symbolId++;
}

private void returnStatement(in ParseTree p)
{
    compile(p.children[0]);
    result ~= Op.ret;
}

private void operation(Op op)(in ParseTree p)
{
    compile(p.children[0]);
    result ~= op;
}

private void identifier(in ParseTree p)
{
    result ~= Op.load;
    result ~= symbolTable[p.matches[0]];
}

private void integer(in ParseTree p)
{
    result ~= Op.push;
    result ~= to!long(p.matches[0]);
}
