import xlang.lexer.lexer;
import std.stdio;


void main(string[] args)
{
    // TODO: getopt for serious argument parsing.
    Lexer lexer = Lexer.fromFile(args[1]);

    foreach (token; lexer.tokens)
        writeln(token);
}
