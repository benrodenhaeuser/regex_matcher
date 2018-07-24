module Rex
  class AST
    attr_accessor :root, :left, :right, :automaton

    def initialize(root: nil, left: nil, right: nil)
      @root = root
      @left = left
      @right = right
    end

    def to_s
      # TODO
    end

    def label_nodes
      left.to_automaton if left
      right.to_automaton if right

      case root.type
      when Tokenizer::ALPHANUMERIC
        self.automaton = Automaton.for_char(root.text)
      when Tokenizer::ANYSINGLECHAR
        self.automaton = Automaton.for_any_single_char
      when Tokenizer::ALTERNATE
        self.automaton = left.automaton.alternate(right.automaton)
      when Tokenizer::CONCATENATE
        self.automaton = left.automaton.concatenate(right.automaton)
      when Tokenizer::STAR
        self.automaton = left.automaton.iterate
      end
    end

    def to_automaton
      label_nodes
      automaton
    end
  end
end
