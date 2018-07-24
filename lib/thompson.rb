module Rex
  module Thompson
    SILENT = ''

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # build automaton that matches the single char given
      def for_char(char)
        start = State.new
        accept_state = State.new
        start.moves[char] = Set[accept_state]
        new(start: start, accept: Set[accept_state])
      end

      # build automaton that matches any single char in ALPHABET
      def for_wildcard
        start = State.new
        accept_state = State.new
        ALPHABET.each { |char| start.moves[char] = Set[accept_state] }
        new(start: start, accept: Set[accept_state])
      end

      # build automaton from abstract syntax tree
      # notice the recursion: AST#to_automaton calls this method
      def from_ast(ast)
        case ast.root.type
        when Tokenizer::ALPHANUMERIC
          Automaton.for_char(ast.root.text)
        when Tokenizer::WILDCARD
          Automaton.for_wildcard
        when Tokenizer::ALTERNATE
          ast.left.to_automaton.alternate(ast.right.to_automaton)
        when Tokenizer::CONCATENATE
          ast.left.to_automaton.concatenate(ast.right.to_automaton)
        when Tokenizer::STAR
          ast.left.to_automaton.iterate
        end
      end
    end

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
end
