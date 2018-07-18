module Rex
  class Node
    attr_accessor :left, :right, :token, :automaton

    def initialize(left: nil, right: nil)
      @left = left
      @right = right
    end
  end

  class AST
    attr_accessor :root, :counter

    def initialize(root: nil)
      @root = root # should be a token
    end

    def label(node = @root)
      return if node == nil

      label(node.left)
      label(node.right)

      if ALPHABET.include?(node.token)
        self.automaton = Automaton.from_char(node.token)
      elsif node.token == '|'
        self.automaton = left.automaton.alternate(right.automaton)
      # further cases omitted (for now)
      end
    end

    def to_automaton
      label
      @root.automaton
    end
  end
end
