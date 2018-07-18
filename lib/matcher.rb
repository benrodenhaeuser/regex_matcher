require_relative './parser.rb'
require_relative './tree.rb'
require_relative './automaton.rb'

# match?(regex, string):
# - parse the regex into an ast
# - label the ast nodes with nfas with a postorder traversal
# - transform `tree.automaton` (the automaton at the root) into a dfa
# - check whether the dfa accepts the string

module Rex
  def self.match?(regex, string) # tentative
    parser = Parser.new
    ast = parser.parse(regex.source)
    nfa = ast.to_automaton
    dfa = nfa.to_dfa
    dfa.accept?(string)
  end

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
    tokenizer = Tokenizer.new('a|b')
    parser = Parser.new(tokenizer)
    automaton = parser.parse
    puts automaton.to_dfa
    # ^ this one looks very odd

    # tokenizer = Tokenizer.new('(c|d)*')
    # parser = Parser.new(tokenizer)
    # automaton = parser.parse
    # puts automaton.to_dfa
    # # ^ this one looks fine

    # tokenizer = Tokenizer.new('a|b*')
    # parser = Parser.new(tokenizer)
    # parser.parse
    # tokenizer = Tokenizer.new('(a|b)*')
    # parser = Parser.new(tokenizer)
    # parser.parse
    # tokenizer = Tokenizer.new('(abcd*|b)*')
    # parser = Parser.new(tokenizer)
    # parser.parse
    # tokenizer = Tokenizer.new('( a b c d*|b )*')
    # parser = Parser.new(tokenizer)
    # parser.parse
    # tokenizer = Tokenizer.new('( a b c d*|b )*')
    # parser = Parser.new(tokenizer)
    # parser.parse
  end
end

# Rex.test_automaton
# puts
# Rex.test_tokenizer
# puts
Rex.test_parser
