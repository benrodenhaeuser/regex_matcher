require_relative './set.rb'
require_relative './token.rb'
require_relative './tokenizer.rb'
require_relative './parser.rb'
require_relative './ast.rb'
require_relative './state.rb'
require_relative './automaton.rb'

module Rex
  class Engine
    def initialize(pattern, string)
      @pattern = pattern
      @string = string
    end

    def match?
      nfa = Parser.new(@pattern).parse.to_automaton
      pre = Automaton.for_wildcard.iterate
      post = Automaton.for_wildcard.iterate
      dfa = pre.concat(nfa.concat(post)).to_dfa
      dfa.accept?(@string)
    end
  end
end
