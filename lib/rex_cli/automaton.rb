require_relative './state.rb'
require_relative './singleton_set.rb'
require_relative './thompson.rb'
require_relative './dfa.rb'

module Rex
  class AutomatonError < RuntimeError; end

  class Automaton
    include Thompson
    include DFA

    def initialize(initial: nil, terminal: nil, alphabet: nil, states: nil)
      @initial  = initial
      @terminal = terminal
      @alphabet = alphabet
      @states   = states
      @current  = @initial
    end

    def step?(char)
      @current.moves[char]
    end

    def step!(char)
      set = @current.moves[char]
      raise AutomatonError, "Not available: #{char}" unless set
      raise AutomatonError, "Nondeterministic: #{char}" unless set.singleton?

      @current = set.element
    end

    def terminal?
      terminal.include?(@current)
    end

    def reset
      @current = @initial
      self
    end

    def to_s
      states.each.with_index { |state, index| state.label = "q#{index}" }

      transitions = states.map(&:collect_transitions).compact.join("\n")

      "states: #{states}\n" \
        "initial: #{initial}\n" \
        "terminal: #{terminal}\n" \
        "alphabet: #{alphabet}\n" \
        "transitions:\n#{transitions}\n"
    end

    protected

    attr_accessor :initial
    attr_accessor :terminal

    def alphabet
      @alphabet ||= compute_alphabet
    end

    def states
      @states ||= compute_states
    end

    private

    def compute_alphabet
      alphabet = states.each_with_object(Set.new) do |state, alph|
        alph.merge(state.alphabet)
      end

      Set[*alphabet.reject { |char| char == '' }]
    end

    def compute_states
      @initial.reachable
    end
  end
end
