module xlang.parser;

import pegged.grammar;


mixin(grammar(`
X:
    Program < Statement*

    Statement <- AssignmentStatement
               / ReturnStatement

    AssignmentStatement < Identifier '=' Expression ';'
    ReturnStatement < "return" Expression ';'

    Expression <- AdditiveExpression
    PrimaryExpression < Identifier
                      / Integer
                      / '(' Expression ')'

    MultiplicativeExpression < PrimaryExpression (Multiplication / Division)*
    Multiplication < '*' PrimaryExpression
    Division       < '/' PrimaryExpression

    AdditiveExpression < MultiplicativeExpression (Addition / Subtraction)*
    Addition    < '+' MultiplicativeExpression
    Subtraction < '-' MultiplicativeExpression

    Identifier <~ identifier
    Integer    <~ digits
`));

