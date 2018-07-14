# regex matcher from scratch

- start out with a regex grammar
- build a regex parser
- build a converter to finite state automaton (in one pass with parsing?)
- check whether given string is accepted by automation

## regex grammar

### constructs

c     matches literal character c
.     matches any single character
^     matches the beginning of the input string
$     matches the end of the input string
v     alternation
      concatenation (no special symbol)
*     closure (Kleene star)

### simple grammar

a simple bnf grammar looks like this:

```
regex = char | regex '|' regex | regex regex | regex'*'
char  = c | '.'
c     = (alphanumeric characters)
```

there are two problems with this grammar though:

- it does not get the precedence rules right.
  - star takes precedence over concatenation (ab* is a followed by some bs)
  - concatenation takes precedence over alternation (ab|cd is ab or cd, not a followed by b or c followed by d)
- it is left-recursive, so our parser is going to run into trouble.

### more involved grammar

here is an ebnf that gets these two problems right:

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

*note that this grammar encodes the precedence rules:*
it is simply not posssible to parse the regex `a | bc` in such a way that the concatenation is higher up in the tree than the alterntion

so this gives us a regex parser.

### from regex to finite state automaton

next, we need to transform the regex to a deterministic finite state automaton. how does this work?

think of the regex operations as denoting operations on automata

- a character denotes an automaton with two distinct states: initial state and accepting state, linked by a char-transition
- for alternation, glue together the start states of the automata denoted by the two regexes
- for composition, glue the end state of the first automaton to the start state of the second
- for closure, collapse the start state and the end state of the automaton.

on second thought, here is a refinement, using silent steps:

- *alternation:* glue together initial states of two automata. (to avoid non-determinism, we have to do more work here, gluing together successor states as well.)
- *composition:* make silent step from accepting states of self to initial state of other
- *closure:* make silent steps from accepting states to initial state (to allow for > 1 iterations). make the initial state an accepting state (to allow for 0 iterations).

(something like this is sometimes called the "Thompson construction")

this construction raises two questions:

- how to deal with non-determinism? the construction may introduce non-determinism. to use the resulting automaton as a recognizer, we have to devise an algorithm that follows all alternative paths through the regex, or we have to make the automaton deterministic first.
- how to implement the automata?

### representation

we could have a class `State` that represents a state in an automation.

instances of the class have three attributes:
- `initial` (true or false)
- `accepting` (true or false)
- `trans` (a hash whose keys are characters, and the values are other instances of state)

### non-determinism

This requires further collapsing of states.


### More notes


- From Regex to DFA: “Thompson construction”
- From NFA to DFA: Subset construction
- Class State: hash table with characters as keys and sets of states as values
- Class Automaton: has an initial state (instance of State) and a set of accepting states (instances of State)
- Match string: Either do an explicit conversion to NFA, or convert on the fly.
- Regex to NFA: by recursion, using the construction I have sketched already.



# Overall architecture

- given a regex and a string
- parse regex
- build NFA from regex parse tree (or AST?)
- convert NFA to DFA
- string accepted by DFA?

`Matcher` class with class method `match?` that takes regex and string. So we invoke it like this:

```ruby
Matcher.match?(regex, string)
```

Here is how `match?` should look like

```ruby
def self.match?(regex, string)
  ast = Parser.parse(regex.source)
  Automaton.new(ast).to_dfa.accept?(string)
end
```

This would require us to be able to *construct an automaton from an ast*.


Steps:

- Implement the regex parser, and have it spit out an abstract syntax tree.
- This seems to require a class AST (trees, basically).
- Or would that be a different responsibility from the parser as such?

Another route would be to convert the regex to postfix notation, and parse from there.
