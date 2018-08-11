require_relative './state.rb'
require_relative './set.rb'
require_relative './thompson.rb'
require_relative './dfa.rb'

module Rex
  class Automaton
    include Thompson
    include DFA

    attr_accessor :initial
    attr_accessor :terminal
    attr_writer   :alphabet
    attr_accessor :current

    def initialize(initial: nil, terminal: nil, alphabet: nil, states: nil)
      @initial  = initial
      @terminal = terminal
      @alphabet = alphabet
      @states   = states
      @current  = @initial
    end

    def alphabet
      @alphabet ||= compute_alphabet
    end

    def compute_alphabet
      alphabet = states.each_with_object(Set.new) do |state, alph|
        alph.merge(state.alphabet)
      end

      Set[*alphabet.reject { |char| char == '' }]
    end

    def states
      @states ||= compute_states
    end

    def compute_states
      @initial.reachable
    end

    def reset
      @current = @initial
      self
    end

    def step?(char)
      current.moves[char]
    end

    def step!(char)
      char_neighbors = @current.moves[char]
      raise "Not available: #{char}" unless char_neighbors
      raise "Nondeterministic step: #{char}" unless char_neighbors.singleton?

      @current = @current.moves[char].elem
    end

    def terminal?
      terminal.include?(current)
    end

    def to_s
      states.each.with_index { |state, index| state.label = "q#{index}" }

      transitions = states.map(&:collect_transitions).compact.join("\n")

      "states: #{states}" \
        "\ninitial: #{initial}" \
        "\nterminal: #{terminal}" \
        "\nalphabet: #{alphabet}" \
        "\ntransitions:\n#{transitions}"
    end
  end
end
