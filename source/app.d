import xlang.lexer.lexer;
import std.stdio;


void main(string[] args)
{
    // TODO: getopt for serious argument parsing.
    Lexer lexer = new Lexer(File(args[1]));

    foreach (token; lexer.tokenize())
        writeln(token);
}
