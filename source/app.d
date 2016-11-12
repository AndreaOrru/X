import xlang.compiler;
import xlang.vm;
import std.algorithm;
import std.stdio;


void main()
{
    string expression = readln();

    writeln(expression.bytecode.run());
}
