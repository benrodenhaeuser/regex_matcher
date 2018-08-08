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
