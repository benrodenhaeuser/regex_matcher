require 'set'

class Set
  def singleton?
    size == 1
  end

  def elem
    raise 'Not a singleton!' unless singleton?
    to_a.first
  end

  def to_s
    '{' + to_a.map(&:to_s).join(', ') + '}'
  end
end

module Rex
  class State
    SILENT = ''
    EPSILON = "\u03B5".encode('utf-8')

    attr_reader   :moves
    attr_accessor :label
    attr_accessor :data

    def initialize(label: nil, data: nil)
      @moves = {}
      @label = label
      @data  = data
    end

    def chars
      moves.keys.reject { |key| key == SILENT }
    end

    def neighbors
      moves.each_value.with_object(Set.new) do |set_of_states, collection|
        collection.merge(set_of_states)
      end
    end

    def reachable(collection = Set[self])
      neighbors.each_with_object(collection) do |neighbor, coll|
        next if coll.include?(neighbor)
        coll.add(neighbor)
        neighbor.reachable(coll)
      end
    end

    def epsilon_closure(collection = Set[self])
      neighbors.each_with_object(collection) do |neighbor, coll|
        next if coll.include?(neighbor)
        if moves[SILENT] && moves[SILENT].include?(neighbor)
          coll.add(neighbor)
          neighbor.epsilon_closure(coll)
        end
      end
    end

    def to_s
      label
    end

    def collect_transitions
      return nil if neighbors.empty?

      moves.map do |char, accessible_states|
        char = (char == SILENT ? EPSILON : char)
        accessible_states.map do |state|
          "#{label} --#{char}--> #{state.label}"
        end
      end.join("\n")
    end

    def alphabet
      moves.keys
    end
  end

  module FromAST
    SILENT = ''

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def from_ast(ast)
        case ast.root.type
        when Tokenizer::CHAR
          Automaton.for_char(ast.root.text)
        when Tokenizer::DOT
          Automaton.for_dot
        when Tokenizer::ALTERNATE
          ast.left.to_automaton.alternate(ast.right.to_automaton)
        when Tokenizer::CONCAT
          ast.left.to_automaton.concat(ast.right.to_automaton)
        when Tokenizer::STAR
          ast.left.to_automaton.iterate
        end
      end

      def for_char(char)
        initial_state = State.new
        terminal_state = State.new
        initial_state.moves[char] = Set[terminal_state]
        new(
          initial:  initial_state,
          terminal: Set[terminal_state],
          alphabet: Set[char],
          states:   Set[initial_state, terminal_state]
        )
      end

      def for_dot
        initial_state = State.new
        terminal_state = State.new
        ALPHABET.each { |char| initial_state.moves[char] = Set[terminal_state] }
        new(
          initial:    initial_state,
          terminal:   Set[terminal_state],
          alphabet: Set[*ALPHABET],
          states:   Set[initial_state, terminal_state]
        )
      end
    end

    def alternate(other)
      new_initial_state = State.new
      new_terminal_state = State.new
      new_initial_state.moves[SILENT] = Set[initial, other.initial]
      terminal.elem.moves[SILENT] = Set[new_terminal_state]
      other.terminal.elem.moves[SILENT] = Set[new_terminal_state]
      self.initial = new_initial_state
      self.terminal = Set[new_terminal_state]
      alphabet.merge(other.alphabet)
      states.merge(other.states).merge([new_initial_state,new_terminal_state])
      self
    end

    def concat(other)
      terminal.elem.moves[SILENT] = Set[other.initial]
      self.terminal = other.terminal
      alphabet.merge(other.alphabet)
      states.merge(other.states)
      self
    end

    def iterate
      new_initial_state = State.new
      new_terminal_state = State.new
      terminal.elem.moves[SILENT] = Set[initial, new_terminal_state]
      new_initial_state.moves[SILENT] = Set[initial, new_terminal_state]
      self.initial = new_initial_state
      self.terminal = Set[new_terminal_state]
      states.merge([new_initial_state, new_terminal_state])
      self
    end
  end

  module ToDFA
    def to_dfa
      dfa_initial = State.new(data: epsilon_closure(Set[initial]))
      dfa_terminal = Set.new
      dfa_states = Set[dfa_initial]
      stack = [dfa_initial]

      until stack.empty?
        q = stack.pop

        dfa_terminal.add(q) if q.data.any? { |elem| terminal.include?(elem) }

        alphabet.each do |char|
          the_neighbors = char_neighbors(q.data, char)
          next if the_neighbors.empty?
          data = epsilon_closure(the_neighbors)
          t = find_state(dfa_states, data) || State.new(data: data)
          q.moves[char] = Set[t] # singleton!
          unless find_state(dfa_states, data)
            dfa_states.add(t)
            stack.push(t)
          end
        end
      end

      Automaton.new(
        initial:  dfa_initial,
        terminal: dfa_terminal,
        alphabet: alphabet,
        states:   dfa_states
      )
    end

    def epsilon_closure(set_of_states)
      set_of_states.each_with_object(Set.new) do |state, closure|
        closure.merge(state.epsilon_closure)
      end
    end

    def char_neighbors(set_of_states, char)
      set_of_states.each_with_object(Set.new) do |state, nb_set|
        nb_set.merge(state.moves[char]) if state.moves[char]
      end
    end

    def find_state(set_of_states, data)
      set_of_states.find { |state| state.data == data }
    end
  end

  class Automaton
    include FromAST
    include ToDFA

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
    end

    def possible_step?(char)
      current.moves[char]
    end

    def step(char)
      char_neighbors = @current.moves[char]
      raise "Not available: #{char}" unless char_neighbors
      raise "Nondeterministic step: #{char}" unless char_neighbors.singleton

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
