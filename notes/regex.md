# regex

## Grammar

### Constructs

c     matches literal character c
^     matches the beginning of the input string
$     matches the end of the input string
v     alternation
      concatenation (no special symbol)
*     closure (Kleene star)

### EBNF

```
 regex ::= term '|' regex | term      // alternation
  term ::= factor { factor }          // concatenation
factor ::= base [ '*' ]               // iteration
  base ::= char | '(' regex ')'
  char ::= 'a' | 'b' | ...
```

- a regex is a term or a regex followed by a term
- a term is a (possibly empty) sequence of factors
- a factor is a base possibly followed by a star
- a base is a character, an escaped character, or a parenthesized regex


## Types of matches

- per line
- global
- ...
