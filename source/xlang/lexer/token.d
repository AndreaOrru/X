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
    int line;
    int column;
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
    Location location;  /// The location of the token.
}
