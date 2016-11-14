module xlang.lexer.token;


/**
 * Enum of all the accepted token types.
 */
enum TokenType
{
    number,  /// [0-9]+
    plus,    /// +
    eof,     /// EOF
};

/**
 * The location of a token in the input.
 */
struct Location
{
    int line;    /// The line in the file.
    int column;  /// The column in the line.
}

/**
 * The token structure.
 *
 * Represents a token in the input.
 */
struct Token
{
    TokenType type;     /// The type of the token.
    string text;        /// The text of the token.
    Location location;  /// The location of the token in the input.

    /**
     * Convert the token structure to a human readable string.
     *
     * Returns:
     *     A string describing the token.
     */
    string toString() const
    {
        import std.string: format;

        return format(`Token(type=%s, text="%s", line=%d, column=%d)`,
            type, text, location.line, location.column);
    }
}
