# a state has a moves attribute: the keys are characters.
# for each key, the value is a list of states.
module Automaton
  class State
    attr_reader :moves
    attr_accessor :label

    def initialize
      @moves = {}
    end

    # accessible in one step
    def neighbors
      moves.reduce([]) do |list, (_, states)|
        states.each do |state|
          list << state unless list.include?(state)
        end
        list
      end
    end

    # accessible in >= 0 steps
    def reachable(list = [self])
      neighbors.each do |neighbor|
        next if list.include?(neighbor)
        list << neighbor
        neighbor.reachable(list)
      end

      list
    end
  end

  # the operations needed for the Thompson construction
  module Thompson
    SILENT = ''

    def alternate(other)
      new_start = State.new
      new_accept_state = State.new
      new_start.moves[SILENT] = [start, other.start]
      accept_list.first.moves[SILENT] = [new_accept_state]
      other.accept_list.first.moves[SILENT] = [new_accept_state]
      self.start = new_start
      self.accept_list = [new_accept_state]
      self
    end

    def compose(other)
      accept_list.first.moves[SILENT] = [other.start]
      self.accept_list = other.accept_list
      self
    end

    def iterate
      new_start = State.new
      new_accept_state = State.new
      accept_list.first.moves[SILENT] = [start, new_accept_state]
      new_start.moves[SILENT] = [start, new_accept_state]
      self.start = new_start
      self.accept_list = [new_accept_state]
      self
    end
  end

  # an automaton has a unique start state
  # and a list of accepting states
  class NFA
    include Thompson

    attr_accessor :start, :accept_list

    def initialize(start_state, accept_list)
      @start = start_state
      @accept_list = accept_list
    end

    def self.from_char(char)
      start = State.new
      accept_state = State.new
      start.moves[char] = [accept_state]
      new(start, [accept_state])
    end

    def accept?(string)
      # move through the automaton.
      # this is easier in a deterministic automaton
      # so we could use that.
    end

    def states
      @start.reachable
    end

    def label_states
      states.each_with_index do |state, index|
        state.label = "q#{index}"
      end
    end

    def to_dfa
      # make the automaton deterministic
      # "subset construction"
    end

    # print a transition table
    def to_s
      label_states
      transitions =
        states.map do |state|
          if !state.moves.empty?
            state.moves.map do |key, value|
              char = (key == '' ? "\u03B5".encode('utf-8') : key)
              "#{state.label}--#{char}-->#{value.map { |elem| elem.label }}"
            end
          else
            "#{state.label}"
          end
        end.join("\n")

      "start: #{start.label} \n" +
      "accepting: #{accept_list.map(&:label)} \n" +
      transitions
    end
  end
end

# TESTS

# automaton for (c|d)*
puts Automaton::NFA.from_char('c').alternate(Automaton::NFA.from_char('d')).iterate
