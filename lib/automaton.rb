require 'set'

class Set
  def singleton?
    size == 1
  end

  def unique_member
    raise 'Not a singleton!' if size != 1
    to_a.first
  end

  def nonempty?
    !empty?
  end

  def to_s
    '{' + to_a.map(&:to_s).join(', ') + '}'
  end
end

module Rex
  module Thompson
    SILENT = ''

    def alternate(other)
      new_start = State.new
      new_accept_state = State.new
      new_start.moves[SILENT] = Set[start, other.start]
      accept.unique_member.moves[SILENT] = Set[new_accept_state]
      other.accept.unique_member.moves[SILENT] = Set[new_accept_state]
      self.start = new_start
      self.accept = Set[new_accept_state]
      self
    end

    def concatenate(other)
      accept.unique_member.moves[SILENT] = Set[other.start]
      self.accept = other.accept
      self
    end

    def iterate
      new_start = State.new
      new_accept_state = State.new
      accept.unique_member.moves[SILENT] = Set[start, new_accept_state]
      new_start.moves[SILENT] = Set[start, new_accept_state]
      self.start = new_start
      self.accept = Set[new_accept_state]
      self
    end
  end

  module DFA
    def to_dfa
      dfa_start = State.new(data: epsilon_closure(Set[self.start]))
      dfa_accept = Set.new

      dfa_states = Set[dfa_start]
      stack = [dfa_start]

      while !stack.empty?
        q = stack.pop

        if q.data.any? { |old_state| accept.include?(old_state) }
          dfa_accept.add(q)
        end

        alphabet.each do |char|
          the_neighbors = neighbors(q.data, char)
          if the_neighbors.nonempty?
            data = epsilon_closure(the_neighbors)
            t = find_state(dfa_states, data) || State.new(data: data)
            q.moves[char] = Set[t]
            if !find_state(dfa_states, data)
              dfa_states.add(t)
              stack.push(t)
            end
          end
        end
      end

      Automaton.new(start: dfa_start, accept: dfa_accept)
    end

    def epsilon_closure(states)
      the_epsilon_closure = Set.new
      states.each do |state|
        the_epsilon_closure.merge(state.epsilon_closure)
      end
      the_epsilon_closure
    end

    def neighbors(states, char)
      the_neighbors = Set.new
      states.each do |state|
        the_neighbors.merge(state.moves[char])
      end
      the_neighbors
    end

    def find_state(dfa_states, data)
      dfa_states.find { |state| state.data == data }
    end
  end

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

    # build automaton that matches the single char given
    def self.for_char(char)
      start = State.new
      accept_state = State.new
      start.moves[char] = Set[accept_state]
      new(start: start, accept: Set[accept_state])
    end

    # build automaton that matches any single char in ALPHABET
    def self.for_any_single_char
      start = State.new
      accept_state = State.new
      ALPHABET.each { |char| start.moves[char] = Set[accept_state] }
      new(start: start, accept: Set[accept_state])
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
