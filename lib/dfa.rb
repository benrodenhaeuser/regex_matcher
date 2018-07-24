module Rex
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
end
