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
  SILENT = ''

  class State
    attr_reader :moves
    attr_accessor :label, :data

    def initialize(label: nil, data: nil)
      @moves = Hash.new { |hash, key| hash[key] = Set.new }
      @label = label
      @data = data
    end

    def to_s
      label
    end

    def transition_string
      if neighbors.empty?
        "#{label}: no transitions"
      else
        moves.map do |char, accessible_states|
          char = (char == '' ? "\u03B5".encode('utf-8') : char)
          accessible_states.map do |state|
            "#{label} --#{char}--> #{state.label}"
          end
        end.join("\n")
      end
    end

    def chars
      moves.keys.reject { |key| key == SILENT }
    end

    def neighbors
      moves.each_with_object(Set.new) do |(_, set_of_states), collection|
        set_of_states.each do |state|
          collection.add(state) unless collection.include?(state)
        end
      end
    end

    def reachable(collection = Set[self])
      neighbors.each do |neighbor|
        next if collection.include?(neighbor)
        collection.add(neighbor)
        neighbor.reachable(collection)
      end

      collection
    end

    def epsilon_closure(collection = Set[self])
      neighbors.each do |neighbor|
        next if collection.include?(neighbor)
        if moves[SILENT].include?(neighbor)
          collection.add(neighbor)
          neighbor.epsilon_closure(collection)
        end
      end

      collection
    end
  end

  module ThompsonConstruction
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

  module SubsetConstruction
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
    include ThompsonConstruction
    include SubsetConstruction

    attr_accessor :start, :accept

    def initialize(start: nil, accept: nil)
      @start = start
      @accept = accept
    end

    def accept?(string)
      # TODO
    end

    def self.from_char(char)
      start = State.new
      accept_state = State.new
      start.moves[char] = Set[accept_state]
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

    def label_all_states
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
