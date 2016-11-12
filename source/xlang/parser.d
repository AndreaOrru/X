module xlang.parser;

import pegged.grammar;


mixin(grammar(`
X:
    Term     < Factor (Add / Sub)*
    Add      < "+" Factor
    Sub      < "-" Factor
    Factor   < Primary (Mul / Div)*
    Mul      < "*" Primary
    Div      < "/" Primary
    Primary  < Parens / Neg / Pos / Number
    Parens   < "(" Term ")"
    Neg      < "-" Primary
    Pos      < "+" Primary
    Number   < ~([0-9]+)
`));

