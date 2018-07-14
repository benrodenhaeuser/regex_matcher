require './automaton.rb'
require './parser.rb'

class Matcher
  def self.match?(regex, string)
    ast = Parser.parse(regex.source)
    Automaton::NFA.new(ast).to_dfa.accept?(string)
  end
end
