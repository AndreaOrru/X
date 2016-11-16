module xlang.parser.ast;

import xlang.lexer.token;
import xlang.utils;


/**
 * The expression class.
 */
abstract class Expression
{
    Token token;  /// The token associated with the expression.

    /**
     * Constructor.
     *
     * Params:
     *     token = associated token
     */
    this(Token token) { this.token = token; }
}

/**
 * The unary expression class.
 */
abstract class UnaryExpression : Expression { mixin InheritConstructors; }

/**
 * The binary expression class.
 *
 * Composed by a left node, an operator and a right node.
 */
class BinaryExpression : Expression
{
    /// The left and right-hand side of the binary expression.
    Expression left, right;

    /// The operator of the binary expression.
    Token operator() const @property { return token; }

    /**
     * Constructor.
     *
     * Params:
     *     left = left-hand side expression
     *     operator = binary operator
     *     right = right-hand side expression
     */
    this(Expression left, Token operator, Expression right)
    {
        super(operator);
        this.left = left;
        this.right = right;
    }
}

class Identifier : UnaryExpression { mixin InheritConstructors; }

/**
 * The integer class.
 */
class Integer : UnaryExpression
{
    int value;  /// The integer value of the expression.

    /**
     * Constructor
     *
     * Params:
     *     integerToken = associated token
     */
    this(Token integerToken)
    {
        super(integerToken);

        import std.conv : to;
        value = to!int(integerToken.text);
    }
}
