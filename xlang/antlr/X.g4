grammar X;


//////////////
//  Parser  //
//////////////

program:
    (varDecl | funcDecl)* ;

varDecl:
    ID ':' typ ('=' expr)? ';' ;

funcDecl:
    ID '(' params? ')' ('->' typ)? block ;

typ
    : 'Int'    # IntType
    | '&' typ  # PtrType
    ;

params:
    param (',' param)* ;

param:
    ID ':' typ ;

lValue
    : ID  # IdExpr
    ;

expr
    : ID '(' exprList? ')'      # CallExpr
    | '-' expr                  # MinusExpr
    | '&' lValue                # RefExpr
    | '@' expr                  # DerefExpr
    | expr op=('*' | '/') expr  # MulDivExpr
    | expr op=('+' | '-') expr  # AddSubExpr
    | expr op=('<' | '<=' | '==' | '!=' | '>=' | '>') expr  # RelExpr
    | lValue                    # LValueExpr
    | INT                       # IntExpr
    | '(' expr ')'              # ParensExpr
    | assign                    # AssignExpr
    ;

exprList:
    expr (',' expr)* ;

block:
    '{' stmt* '}' ;

blockOrStmt
    : block
    | stmt ;

stmt
    : varDecl
    | ifElse
    | whileLoop
    | block
    | assign ';'
    | ret
    | expr   ';' ;

ifElse:
    'if' '(' expr ')' blockOrStmt ('else' blockOrStmt)? ;

whileLoop:
    'while' '(' expr ')' blockOrStmt ;

assign:
    ID '=' expr ;

ret:
    'return' expr? ';' ;


/////////////
//  Lexer  //
/////////////

ID:
    Letter (Letter | Digit)* ;

INT:
    Digit+ ;

fragment Digit:
    [0-9] ;

fragment Letter:
    [a-zA-Z] ;

SPACE:
    [ \t\n\r]+ -> skip ;

COMMENT:
    '//' ~[\r\n]* -> skip ;
