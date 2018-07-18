module Rex
  ALPHABET = ['a', 'b', 'c', 'd', 'e', 'f',
                'g', 'h', 'i', 'j', 'k', 'l',
                'm', 'n', 'o', 'p', 'q', 'r',
                's', 't', 'u', 'v', 'w', 'x',
                'y', 'z',
                'A', 'B', 'C', 'D', 'E', 'F',
                'G', 'H', 'I', 'J', 'K', 'L',
                'M', 'N', 'O', 'P', 'Q', 'R',
                'S', 'T', 'U', 'V', 'W', 'X',
                'Y', 'Z']

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

    # the root node will contain the automaton that matches the parsed regex.
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
