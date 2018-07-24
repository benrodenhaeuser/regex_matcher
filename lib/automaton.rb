require_relative 'thompson.rb'
require_relative 'dfa.rb'

module Rex
  class Automaton
    include Thompson
    include DFA

    attr_accessor :start, :accept

    def initialize(start: nil, accept: nil)
      @start = start
      @accept = accept
    end

    def accept?(string)
      dfa = self.to_dfa
      current_state = dfa.start
      string.each_char do |char|
        if current_state.moves[char].nonempty?
          current_state = current_state.moves[char].unique_member
        else
          return false
        end
      end
      dfa.accept.include?(current_state)
    end

    def state_space
      @start.reachable
    end

    def alphabet
      chars = Set.new

      state_space.each do |state|
        chars.merge(Set[*state.moves.keys])
      end

      Set[*chars.reject { |char| char == '' }]
    end

    def label_all_states # for pretty printout
      index = 0

      state_space.each do |state|
        state.label = "q#{index}"
        index += 1
      end
    end

    def to_s
      label_all_states
      transitions = state_space.map do |state|
        state.transition_string
      end.join("\n")
      "start: #{start}" + "\naccept: #{accept}" + "\ntransitions:\n#{transitions}"
    end
  end
end
