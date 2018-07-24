module Rex
  class AST
    attr_accessor :root, :left, :right, :automaton

    def initialize(root: nil, left: nil, right: nil)
      @root = root
      @left = left
      @right = right
    end

    def to_automaton
      Automaton.from_ast(self)
    end
  end
end
