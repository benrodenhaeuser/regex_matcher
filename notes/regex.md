# regex

## grammar

### Constructs

c     matches literal character c
^     matches the beginning of the input string
$     matches the end of the input string
v     alternation
      concatenation (no special symbol)
*     closure (Kleene star)

### EBNF

```
  <regex> ::= <term> '|' <regex> | <term>
   <term> ::= { <factor> }
 <factor> ::= <base> [ '*' ]
   <base> ::= <char> | '.' | '(' <regex> ')'
   <char> ::= 'a' | 'b' | ... | 'z' | 'A' | 'B' | ... | 'Z'
```

- a regex is a term or a regex followed by a term
- a term is a (possibly empty) sequence of factors
- a factor is a base possibly followed by a star
- a base is a character, an escaped character, or a parenthesized regex
