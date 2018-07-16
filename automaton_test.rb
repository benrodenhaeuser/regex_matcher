require_relative 'automaton.rb'

automaton =  Matcher::Automaton.from_char('c').alternate(Matcher::Automaton.from_char('d')).iterate
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
