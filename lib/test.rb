require_relative './token.rb'
require_relative './tokenizer.rb'
require_relative './parser.rb'
require_relative './tree.rb'
require_relative './automaton.rb'

module Rex
  def self.test_automaton
    c = Automaton.from_char('c')
    d = Automaton.from_char('d')
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

    # 'a|b*'
    # '(abcd*|b)*'
    parser = Parser.new('ab')    # step 0: initialize parser with source
    ast = parser.parse            # step 1: parse source into ast
    nfa = ast.to_automaton        # step 2: build nfa from ast
    dfa = nfa.to_dfa              # step 3: convert nfa to dfa
    p dfa.accept?('ab') == true
    p dfa.accept?('aa') == false
  end
end

# Rex.test_automaton
# Rex.test_tokenizer
# Rex.test_parser
Rex.test_pipeline
