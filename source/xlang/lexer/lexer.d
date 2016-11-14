module xlang.lexer.lexer;

import xlang.lexer.token;
import std.file;
import std.stdio;
import std.uni;


/**
 * The lexer class.
 *
 * Reads a file and splits it into tokens.
 */
class Lexer
{
    /**
     * Constructor from text.
     *
     * Params:
     *     input = the text to tokenize
     */
    this(string input)
    {
        this.input = input;
        tokenize();
    }

    /**
     * Constructor from file.
     *
     * Params:
     *     file = file to tokenize
     */
    static Lexer fromFile(string fileName)
    {
        string input = readText(fileName);
        return new Lexer(input);
    }

    /**
     * The tokenized input.
     */
    const(Token[]) tokens() const @property
    {
        return _tokens;
    }

  private:
    Token[] _tokens;    /// The list of the tokens.
    string input;       /// The content of the file.
    int index = 0;      /// The current position in the file.

    /// The current location (line/column) in the file.
    Location location = {1, 1};

    /**
     * Tokenize the input.
     */
    void tokenize()
    {
        int c;
        while ((c = peek()) != EOF)
        {
            switch (c)
            {
                case ' ', '\t', '\r', '\n':
                    skipWhitespace(); break;

                case '0': .. case '9':
                    readNumber(); break;

                case '+':
                    addToken(TokenType.plus, "+"); break;

                default:
                    // TODO: unknown token.
                    assert(0);
            }
        }
        // End of file:
        addToken(TokenType.eof, "EOF", location);
    }
    unittest
    {
        Lexer lexer = new Lexer("\t123\r\n+ 4\n");

        assert(lexer.tokens[0] == Token(TokenType.number, "123", Location(1, 2)));
        assert(lexer.tokens[1] == Token(TokenType.plus,   "+",   Location(2, 1)));
        assert(lexer.tokens[2] == Token(TokenType.number, "4",   Location(2, 3)));
        assert(lexer.tokens[3] == Token(TokenType.eof,    "EOF", Location(3, 1)));
    }

    /**
     * Look ahead at the next character without updating the current location.
     *
     * Returns:
     *     The next character or EOF if all characters have been read.
     */
    int peek() const
    {
        if (index < input.length)
            return input[index];
        else
            return EOF;
    }
    unittest
    {
        Lexer lexer = new Lexer;
        lexer.input = "1";
        assert(lexer.peek() == '1');
        assert(lexer.location == Location(1, 1));

        lexer = new Lexer;
        lexer.input = "";
        assert(lexer.peek() == EOF);
    }

    /**
     * Consume the next character and update the current location.
     *
     * Returns:
     *     The next character.
     */
    int read()
    {
        int c = peek();
        index++;

        // Handle newlines:
        if (c == '\n')
        {
            location.line++;
            location.column = 1;
        }
        else
            location.column++;

        return c;
    }
    unittest
    {
        Lexer lexer = new Lexer;
        lexer.input = "1\n";

        assert(lexer.read() == '1');
        assert(lexer.read() == '\n');
        assert(lexer.location.line == 2);
    }

    /**
     * Add a new token to the list.
     *
     * Params:
     *     type = type of the token
     *     text = text of the token
     *     location = location of the token in the input
     */
    void addToken(TokenType type, string text, Location location)
    {
        _tokens ~= Token(type, text, location);
    }

    /**
     * Add the new token at the current location to the list.
     * Update the current location in the process.
     *
     * Params:
     *     type = type of the token
     *     text = text of the token
     */
    void addToken(TokenType type, string text)
    {
        _tokens ~= Token(type, text, this.location);

        // Skip over the token and update the location:
        for (int i = 0; i < text.length; i++)
            read();
    }
    unittest
    {
        Lexer lexer = new Lexer;
        lexer.addToken(TokenType.number, "123");

        assert(lexer.tokens.length == 1);
        assert(lexer.location.column == 4);
    }

    /**
     * Skip whitespace.
     */
    void skipWhitespace()
    {
        do
        {
            read();
        }
        while (isWhite(peek()));
    }
    unittest
    {
        string text = "\n123 + 745     +\t\t \r 12";
        Lexer lexer = new Lexer(text);

        assert(lexer.tokens.length == 6);
        assert(lexer.location.line == 2);
        assert(lexer.location.column == 1 + text.length - 1);
    }

    /**
     * Read a number.
     */
    void readNumber()
    {
        // Save the location at the beginning of the number:
        Location numberLocation = location;

        string number;

        do
        {
            number ~= read();
        }
        while (isNumber(peek()));

        addToken(TokenType.number, number, numberLocation);
    }
    unittest
    {
        string text = "1234567890";
        Lexer lexer = new Lexer;
        lexer.input = text;
        lexer.readNumber();

        assert(lexer.tokens[0].type == TokenType.number);
        assert(lexer.tokens[0].text == text);
        assert(lexer.tokens[0].location == Location(1, 1));
        assert(lexer.location.column == 1 + text.length);
    }

    /**
     * Constructor.
     */
    this() {}
}
