require_relative './parser.rb'
require_relative './tree.rb'
require_relative './automaton.rb'

# match?(regex, string):
# - parse the regex into an ast
# - label the ast nodes with nfas with a postorder traversal
# - transform `tree.automaton` (the automaton at the root) into a dfa
# - check whether the dfa accepts the string

module Rex
  def self.match?(regex, string)
    Automaton.from_ast(Parser.parse(regex.source)).to_dfa.accept?(string)
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

  def self.test_scanner
    scanner = Rex::Scanner.new('a|b*')
    p scanner.next_token # a
    p scanner.next_token # |
    p scanner.next_token # b
    p scanner.next_token # *
    p scanner.next_token # <eof>
  end

  def self.test_parser

  end
end

Rex.test_automaton
puts
Rex.test_scanner
