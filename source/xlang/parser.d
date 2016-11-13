module xlang.parser;

import pegged.grammar;


mixin(grammar(`
X:
    Expression <- AdditiveExpression
    PrimaryExpression < Integer
                      / '(' Expression ')'

    MultiplicativeExpression < PrimaryExpression (Multiplication / Division)*
    Multiplication < '*' PrimaryExpression
    Division       < '/' PrimaryExpression

    AdditiveExpression < MultiplicativeExpression (Addition / Subtraction)*
    Addition    < '+' MultiplicativeExpression
    Subtraction < '-' MultiplicativeExpression

    Integer <~ digits
`));

