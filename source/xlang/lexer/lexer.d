module xlang.lexer.lexer;

public import xlang.lexer.token;
import std.stdio : EOF;


/**
 * The lexer class.
 *
 * Reads a file and splits it into tokens.
 */
final class Lexer
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
        import std.file : readText;

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
                    readInteger(); break;

                case '_':
                case 'a': .. case 'z':
                case 'A': .. case 'Z':
                    readIdentifier(); break;

                case '+':
                    addToken(TokenType.add, "+"); break;

                case '-':
                    addToken(TokenType.sub, "-"); break;

                case '*':
                    addToken(TokenType.mul, "*"); break;

                case '/':
                    addToken(TokenType.div, "/"); break;

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
        Lexer lexer = new Lexer("\t123\r\n+ 4\n/3*x\n");

        assert(lexer.tokens[0] == Token(TokenType.integer,    "123", Location(1, 2)));
        assert(lexer.tokens[1] == Token(TokenType.add,        "+",   Location(2, 1)));
        assert(lexer.tokens[2] == Token(TokenType.integer,    "4",   Location(2, 3)));
        assert(lexer.tokens[3] == Token(TokenType.div,        "/",   Location(3, 1)));
        assert(lexer.tokens[4] == Token(TokenType.integer,    "3",   Location(3, 2)));
        assert(lexer.tokens[5] == Token(TokenType.mul,        "*",   Location(3, 3)));
        assert(lexer.tokens[6] == Token(TokenType.identifier, "x",   Location(3, 4)));
        assert(lexer.tokens[7] == Token(TokenType.eof,        "EOF", Location(4, 1)));
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
        lexer.addToken(TokenType.integer, "123");

        assert(lexer.tokens.length == 1);
        assert(lexer.location.column == 4);
    }

    /**
     * Skip whitespace.
     */
    void skipWhitespace()
    {
        import std.uni : isWhite;

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

    void readIdentifier()
    {
        import std.uni : isAlphaNum;

        Location identifierLocation = location;
        string identifier;

        identifier ~= read();
        while (isAlphaNum(peek()) || peek() == '_')
            identifier ~= read();

        addToken(TokenType.identifier, identifier, identifierLocation);
    }
    unittest
    {
        string[] texts = ["variableName", "_private_Method1"];
        foreach (text; texts)
        {
            Lexer lexer = new Lexer;
            lexer.input = text;
            lexer.readIdentifier();
            assert(lexer.tokens[0] == Token(TokenType.identifier, text, Location(1, 1)));
        }
    }

    /**
     * Read an integer.
     */
    void readInteger()
    {
        import std.uni : isNumber;

        Location integerLocation = location;
        string integer;

        do
        {
            integer ~= read();
        }
        while (isNumber(peek()));

        addToken(TokenType.integer, integer, integerLocation);
    }
    unittest
    {
        string text = "1234567890";
        Lexer lexer = new Lexer;
        lexer.input = text;
        lexer.readInteger();

        assert(lexer.tokens[0] == Token(TokenType.integer, text, Location(1, 1)));
        assert(lexer.location.column == 1 + text.length);
    }

    /**
     * Constructor.
     */
    this() {}
}
