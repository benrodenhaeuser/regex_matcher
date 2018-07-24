require_relative './set.rb'
require_relative './token.rb'
require_relative './tokenizer.rb'
require_relative './parser.rb'
require_relative './ast.rb'
require_relative './state.rb'
require_relative './automaton.rb'

module Rex
  def self.test_automaton
    c = Automaton.for_char('c')
    d = Automaton.for_char('d')
    automaton = c.alternate(d).iterate
    puts "Automaton for '(c|d)*' via Thompson construction:"
    puts automaton # transition table
    puts
    puts "State space:"
    puts automaton.state_space # a set of eight states
    puts "Alphabet:"
    puts automaton.alphabet # set containing 'c' and 'd'
    puts "Epsilon closure of start state:"
    puts Set[*automaton.start.epsilon_closure.map(&:label)]
    # {q0, q1, q2, q4, q5, q6}
    puts
    dfa = automaton.to_dfa # looks odd
    puts "Converted to dfa via Subset construction:"
    puts dfa
    puts
    puts "State space of dfa:"
    puts dfa.state_space
    puts "Accepting states of dfa:"
    puts dfa.accept
    puts "Start state of dfa:"
    puts dfa.start
  end

  def self.test_tokenizer
    tokenizer = Tokenizer.new('a|b*')
    while tokenizer.cursor != Tokenizer::EOF
      p tokenizer.next_token
    end
    puts
    tokenizer = Tokenizer.new('(a|b)*')
    while tokenizer.cursor != Tokenizer::EOF
      p tokenizer.next_token
    end
    puts
    tokenizer = Tokenizer.new('(abc|b)*')
    while tokenizer.cursor != Tokenizer::EOF
      p tokenizer.next_token
    end
    tokenizer = Tokenizer.new('(abcd*|b)*')
    while tokenizer.cursor != Tokenizer::EOF
      p tokenizer.next_token
    end
  end

  def self.test_parser
    puts Parser.new('a|b').parse.to_automaton.to_dfa # fine
  end

  def self.test_pipeline
    parser = Parser.new('a|b')    # step 0: initialize parser with source
    ast = parser.parse            # step 1: parse source into ast
    nfa = ast.to_automaton        # step 2: build nfa from ast
    dfa = nfa.to_dfa              # step 3: convert nfa to dfa

    # another setup would be to have the "engine" (automaton) produce the
    # automaton by feeding it an ast.
    # or a separate matcher class builds the automaton.
    # this would mean to move the `label_nodes` and `to_automaton` methods from
    # the AST class somewhere else.

    # I think what is missing is a `Regex` class that orchestrates the other
    # classes.

    p dfa.accept?('a') == true
    p dfa.accept?('b') == true
    p dfa.accept?('c') == false
    p dfa.accept?('aa') == false

    parser = Parser.new('(a|b)*')
    ast = parser.parse
    nfa = ast.to_automaton
    dfa = nfa.to_dfa
    p dfa.accept?('a') == true
    p dfa.accept?('b') == true
    p dfa.accept?('aaa') == true
    p dfa.accept?('abab') == true

    parser = Parser.new('ab')
    ast = parser.parse
    nfa = ast.to_automaton
    dfa = nfa.to_dfa
    p dfa.accept?('ab') == true
    p dfa.accept?('aa') == false

    parser = Parser.new('(a|b)(c|d)')
    ast = parser.parse
    nfa = ast.to_automaton
    dfa = nfa.to_dfa
    p dfa.accept?('ac') == true
    p dfa.accept?('aa') == false

    # 'a|b*'
    # '(abcd*|b)*'
  end

  def self.test_any_char
    parser = Parser.new('.')
    ast = parser.parse
    nfa = ast.to_automaton
    dfa = nfa.to_dfa
    p dfa.accept?('a') == true
    p dfa.accept?('A') == true
    p dfa.accept?('B') == true
    p dfa.accept?('c') == true
    p dfa.accept?('?') == false
    p dfa.accept?('ab') == false
    p dfa.accept?('') == false
  end

  def self.test_substring_matching
    parser = Parser.new('ab')
    ast = parser.parse
    nfa_for_regex = ast.to_automaton
    pre = Automaton.for_wildcard.iterate
    post = Automaton.for_wildcard.iterate
    nfa = pre.concatenate(nfa_for_regex.concatenate(post))
    dfa = nfa.to_dfa
    p dfa.accept?('mabelle') == true
    p dfa.accept?('mobelle') == false

    parser = Parser.new('ab*')
    ast = parser.parse
    nfa_for_regex = ast.to_automaton
    pre = Automaton.for_wildcard.iterate
    post = Automaton.for_wildcard.iterate
    nfa = pre.concatenate(nfa_for_regex.concatenate(post))
    dfa = nfa.to_dfa
    p dfa.accept?('mabelle') == true
    p dfa.accept?('mobelle') == false
    p dfa.accept?('mabbelle') == true
    p dfa.accept?('ma') == true
    p dfa.accept?('mo') == false
  end
end

Rex.test_automaton
Rex.test_tokenizer
Rex.test_parser
Rex.test_pipeline
Rex.test_any_char
Rex.test_substring_matching
