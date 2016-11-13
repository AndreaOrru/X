import xlang.compiler;
import xlang.vm;
import std.algorithm;
import std.stdio;


void main()
{
    writeln(">>> Enter code to evaluate. Press Ctrl+D to finish inserting.");

    string expression;
    readf("%s", &expression);

    writeln("\n>>> Result of the evaluation:");
    writeln(expression.bytecode.run());
}
