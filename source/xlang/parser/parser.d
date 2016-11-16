module xlang.parser.parser;

import xlang.parser.ast;
import xlang.lexer.token;


/**
 * The parser class.
 *
 * Reads a stream of tokens and parses them into an Abstract Syntax Tree.
 */
final class Parser
{
    /**
     * Constructor.
     *
     * Params:
     *     tokens = the tokens to parse
     */
    this(in Token[] tokens)
    {
        this.tokens = tokens;
        parse();
    }

    /**
     * The Abstract Syntax Tree resulting from the parsing.
     */
    const(Expression) ast() const @property
    {
        return _ast;
    }

  private:
    const Token[] tokens;  /// The tokens to be parsed.
    int tokenIndex = 0;    /// Index inside the token array.
    Expression _ast;       /// The resulting Abstract Syntax Tree.
    Token nextToken;       /// The next token to consider.

    /**
     * Parse the tokens.
     */
    void parse()
    {
        getToken();
        _ast = expression();
    }

    /**
     * Return the current token and advance to the next token in the stream.
     *
     * Returns:
     *     The current token.
     */
    Token getToken()
    {
        Token currentToken = nextToken;
        nextToken = tokens[tokenIndex++];
        return currentToken;
    }

    /**
     * Parse an expression.
     *
     * Returns:
     *     An expression node.
     */
    Expression expression()
    {
        return binaryExpression();
    }

    Expression unaryExpression()
    {
        switch (nextToken.type)
        {
            case TokenType.integer:    return integer();
            case TokenType.identifier: return identifier();
            default: assert(0);
        }
    }

    Expression binaryExpression(int precedence = 0)
    {
        // Get the left hand side:
        Expression x = unaryExpression();

        // While the binding power of the next token is larger:
        while (precedence < nextToken.precedence)
        {
            Token operator = getToken();
            Expression y = binaryExpression(operator.precedence);
            x = new BinaryExpression(x, operator, y);
        }

        return x;
    }

    Expression identifier()
    {
        return new Identifier(getToken());
    }

    Expression integer()
    {
        return new Integer(getToken());
    }
}
