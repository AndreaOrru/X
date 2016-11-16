import xlang.lexer.lexer;
import xlang.parser.parser;


void main(string[] args)
{
    // TODO: getopt for serious argument parsing.

    Lexer lexer = Lexer.fromFile(args[1]);
    Parser parser = new Parser(lexer.tokens);
}
