module Rex
  module DFA
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
end
