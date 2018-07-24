module Rex
  class State
    SILENT = ''

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
end
