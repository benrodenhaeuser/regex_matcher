require_relative './automaton.rb'
require_relative './parser.rb'

module Matcher
  def self.test
    puts Automaton.from_char('c')
    puts "Succeeded building an automaton"
  end

  def self.match?(regex, string)
    Automaton.from_ast(Parser.parse(regex.source)).to_dfa.accept?(string)
  end
end

Matcher.test

# command line application
