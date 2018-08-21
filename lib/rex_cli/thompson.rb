module Rex
  module Thompson
    SILENT = ''

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def from_ast(ast)
        case ast.root.type
        when Tokenizer::CHAR
          char_automaton(ast.root.text)
        when Tokenizer::DOT
          dot_automaton
        when Tokenizer::ALTERNATE
          ast.left.to_automaton.alternate(ast.right.to_automaton)
        when Tokenizer::CONCAT
          ast.left.to_automaton.concat(ast.right.to_automaton)
        when Tokenizer::OPTION
          ast.left.to_automaton.alternate(empty_automaton)
        when Tokenizer::STAR
          ast.left.to_automaton.iterate
        end
      end

      def empty_automaton
        state = State.new
        new(
          initial: state,
          terminal: Set[state],
          alphabet: Set.new,
          states: Set[state]
        )
      end

      def char_automaton(char)
        initial_state = State.new
        terminal_state = State.new
        initial_state.link_to(char, terminal_state)
        new(
          initial:  initial_state,
          terminal: Set[terminal_state],
          alphabet: Set[char],
          states:   Set[initial_state, terminal_state]
        )
      end

      def dot_automaton
        initial_state = State.new
        terminal_state = State.new
        ALPHABET.each { |char| initial_state.link_to(char, terminal_state) }
        new(
          initial:  initial_state,
          terminal: Set[terminal_state],
          alphabet: Set[*ALPHABET],
          states:   Set[initial_state, terminal_state]
        )
      end
    end

    def alternate(other)
      new_initial_state = State.new
      new_initial_state.link_to(SILENT, initial, other.initial)
      new_terminal_state = State.new
      new_terminal_state.link_from(SILENT, terminal.elem, other.terminal.elem)
      self.initial = new_initial_state
      self.terminal = Set[new_terminal_state]
      alphabet.merge(other.alphabet)
      states.merge(other.states).merge([new_initial_state, new_terminal_state])
      self
    end

    def concat(other)
      terminal.elem.link_to(SILENT, other.initial)
      self.terminal = other.terminal
      alphabet.merge(other.alphabet)
      states.merge(other.states)
      self
    end

    def iterate
      new_initial_state = State.new
      new_terminal_state = State.new
      terminal.elem.link_to(SILENT, initial, new_terminal_state)
      new_initial_state.link_to(SILENT, initial, new_terminal_state)
      self.initial = new_initial_state
      self.terminal = Set[new_terminal_state]
      states.merge([new_initial_state, new_terminal_state])
      self
    end
  end
end
