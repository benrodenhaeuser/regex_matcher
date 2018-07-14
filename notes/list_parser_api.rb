=begin

grammar:

list = [elements]
elements = element (, element)*
element = NAME | list
NAME = ('a'..'z' |'A'..'Z' )+

classes:

class Token
- @type
- @text
- to_s

class Lexer
- @input
- @p ('position')
- @c ('character')
- consume
    increment @p
    set @c to @input[@p] or EOF
- match(ch)
    if ch == @c: consume
    else fail

class ListLexer < Lexer
- constants for token types
- letter?
    checks whether cursor/lookahead character is a letter
- next_token
     gets the next token and consumes (moves cursor to end of token)
- name
    auxiliary method for name tokens (segments of letters)

class Parser
- @lookahead (the token under the parser cursor, already consumed by lexer)
- match(expected)
    if lookahead.type == expected: self.consume
    else fail
- consume
    shift lookahead to next token

class ListParser < Parser
- list
- elements
- element

=end
