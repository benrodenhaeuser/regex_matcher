require 'colorize'
require 'set'

class Set
  def singleton?
    size == 1
  end

  def elem
    raise 'Not a singleton!' unless singleton?
    to_a.first
  end

  def to_s
    '{' + to_a.map(&:to_s).join(', ') + '}'
  end
end

module Rex
  ALPHABET = (32..126).map { |int| int.chr(Encoding::ASCII) }
  # ^ "Basic Latin" character set
  #   see https://en.wikipedia.org/wiki/List_of_Unicode_characters#Basic_Latin

  class Token
    attr_reader :type
    attr_reader :text

    def initialize(type, text)
      @type = type
      @text = text
    end
  end

  class Tokenizer
    EOF        = -1
    START_TYPE = 0
    EOF_TYPE   = 1
    CHAR       = 2
    DOT        = 3
    CARET      = 4
    DOLLAR     = 5
    CONCAT     = 6
    ALTERNATE  = 7
    STAR       = 8
    LPAREN     = 9
    RPAREN     = 10

    BACKSLASH = ' \ '.strip

    attr_reader :cursor

    def initialize(source)
      @source   = source
      @position = 0
      @cursor   = @source[@position]
    end

    def next_token
      consume while white_space

      token =
        case @cursor
        when EOF
          Token.new(EOF_TYPE, '<eof>')
        when '('
          Token.new(LPAREN, @cursor)
        when ')'
          Token.new(RPAREN, @cursor)
        when '*'
          Token.new(STAR, @cursor)
        when '|'
          Token.new(ALTERNATE, @cursor)
        when '.'
          Token.new(DOT, @cursor)
        when '^'
          Token.new(CARET, @cursor)
        when '$'
          Token.new(DOLLAR, @cursor)
        when BACKSLASH
          consume
          raise "illegal char #{@cursor}" unless ALPHABET.include?(@cursor)
          Token.new(CHAR, @cursor)
        else
          raise "illegal char #{@cursor}" unless ALPHABET.include?(@cursor)
          Token.new(CHAR, @cursor)
        end

      consume
      token
    end

    def consume
      @position += 1
      @cursor = (@position < @source.length ? @source[@position] : EOF)
    end

    # TODO: take into account other "kinds" of whitespace?
    def white_space
      [' ', '\n'].include?(@cursor)
    end
  end

  class Parser
    attr_reader :lookahead

    def initialize(source)
      @tokenizer = Tokenizer.new(source)
      consume
    end

    def match(expected_type)
      return consume if lookahead.type == expected_type
      raise "Mismatch! Expected #{expected_type}, saw #{lookahead.type}"
    end

    def consume
      @lookahead = @tokenizer.next_token
    end

    def eof?
      lookahead.type == Tokenizer::EOF_TYPE
    end

    def parse
      ast = regex
      raise 'Expected end of stream' unless eof?
      ast
    end

    def regex
      left_ast = term
      if lookahead.type == Tokenizer::ALTERNATE
        token = lookahead
        match(Tokenizer::ALTERNATE)
        right_ast = regex
      end

      return left_ast unless right_ast
      AST.new(root: token, left: left_ast, right: right_ast)
    end

    def term
      factor_first = [
        Tokenizer::CHAR,
        Tokenizer::DOT,
        Tokenizer::DOLLAR,
        Tokenizer::CARET,
        Tokenizer::LPAREN
      ]

      ast = factor
      return ast unless factor_first.include?(lookahead.type)
      token = Token.new(Tokenizer::CONCAT, '')
      AST.new(root: token, left: ast, right: term)
    end

    def factor
      ast = base
      return ast unless lookahead.type == Tokenizer::STAR
      token = lookahead
      match(Tokenizer::STAR)
      AST.new(root: token, left: ast)
    end

    def atomic_ast(lookahead)
      token = lookahead
      match(token.type)
      AST.new(root: token)
    end

    def base
      atomic_expressions = [
        Tokenizer::CHAR,
        Tokenizer::CARET,
        Tokenizer::DOLLAR,
        Tokenizer::DOT
      ]

      type = lookahead.type

      if atomic_expressions.include?(type)
        atomic_ast(lookahead)
      elsif type == Tokenizer::LPAREN
        match(Tokenizer::LPAREN)
        ast = regex
        match(Tokenizer::RPAREN)
        ast
      end
    end
  end

  class AST
    attr_accessor :root
    attr_accessor :left
    attr_accessor :right

    def initialize(root: nil, left: nil, right: nil)
      @root  = root
      @left  = left
      @right = right
    end

    def to_automaton
      Automaton.from_ast(self)
    end
  end

  class State
    SILENT = ''
    EPSILON = "\u03B5".encode('utf-8')

    attr_reader   :moves
    attr_accessor :label
    attr_accessor :data

    def initialize(label: nil, data: nil)
      @moves = Hash.new
      @label = label
      @data  = data
    end

    def to_s
      label
    end

    def transition_string
      return nil if neighbors.empty?

      moves.map do |char, accessible_states|
        char = (char == SILENT ? EPSILON : char)
        accessible_states.map do |state|
          "#{label} --#{char}--> #{state.label}"
        end
      end.join("\n")
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
        if moves[SILENT] && moves[SILENT].include?(neighbor)
          collection.add(neighbor)
          neighbor.epsilon_closure(collection)
        end
      end

      collection
    end
  end

  module FromAST
    SILENT = ''

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def from_ast(ast)
        case ast.root.type
        when Tokenizer::CHAR
          Automaton.for_char(ast.root.text)
        when Tokenizer::DOT
          Automaton.for_dot
        when Tokenizer::CARET
          Automaton.for_caret
        when Tokenizer::DOLLAR
          Automaton.for_dollar
        when Tokenizer::ALTERNATE
          ast.left.to_automaton.alternate(ast.right.to_automaton)
        when Tokenizer::CONCAT
          ast.left.to_automaton.concat(ast.right.to_automaton)
        when Tokenizer::STAR
          ast.left.to_automaton.iterate
        end
      end

      def for_char(char)
        initial = State.new
        terminal_state = State.new
        initial.moves[char] = Set[terminal_state]
        new(
          initial:  initial,
          terminal: Set[terminal_state],
          alphabet: Set[char],
          states:   Set[initial, terminal_state]
        )
      end

      def for_caret
        initial = State.new
        terminal_state = State.new
        initial.moves['\^'] = Set[terminal_state]
        new(
          initial:  initial,
          terminal: Set[terminal_state],
          alphabet: Set['\^'],
          states:   Set[initial, terminal_state]
        )
      end

      def for_dollar
        initial = State.new
        terminal_state = State.new
        initial.moves['\$'] = Set[terminal_state]
        new(
          initial:  initial,
          terminal: Set[terminal_state],
          alphabet: Set['\$'],
          states:   Set[initial, terminal_state]
        )
      end

      def for_dot
        initial = State.new
        terminal_state = State.new
        ALPHABET.each { |char| initial.moves[char] = Set[terminal_state] }
        new(
          initial:    initial,
          terminal:   Set[terminal_state],
          alphabet: Set[*ALPHABET],
          states:   Set[initial, terminal_state]
        )
      end
    end

    def alternate(other)
      new_initial = State.new
      new_terminal_state = State.new
      new_initial.moves[SILENT] = Set[initial, other.initial]
      terminal.elem.moves[SILENT] = Set[new_terminal_state]
      other.terminal.elem.moves[SILENT] = Set[new_terminal_state]
      self.initial = new_initial
      self.terminal = Set[new_terminal_state]
      alphabet.merge(other.alphabet)
      states.merge(other.states).add(new_initial).add(new_terminal_state)
      # ^ TODO: simplify?
      self
    end

    def concat(other)
      terminal.elem.moves[SILENT] = Set[other.initial]
      self.terminal = other.terminal
      alphabet.merge(other.alphabet)
      states.merge(other.states)
      self
    end

    def iterate
      new_initial = State.new
      new_terminal_state = State.new
      terminal.elem.moves[SILENT] = Set[initial, new_terminal_state]
      new_initial.moves[SILENT] = Set[initial, new_terminal_state]
      self.initial = new_initial
      self.terminal = Set[new_terminal_state]
      states.add(new_initial).add(new_terminal_state)
      # ^ TODO: simplify?
      self
    end
  end

  module ToDFA
    def to_dfa
      dfa_initial = State.new(data: epsilon_closure(Set[initial]))
      dfa_terminal = Set.new

      dfa_states = Set[dfa_initial]
      stack = [dfa_initial]

      until stack.empty?
        q = stack.pop

        if q.data.any? { |substate| terminal.include?(substate) }
          dfa_terminal.add(q)
        end

        alphabet.each do |char|
          the_neighbors = neighbors(q.data, char)
          next if the_neighbors.empty?
          data = epsilon_closure(the_neighbors)
          t = find_state(dfa_states, data) || State.new(data: data)
          q.moves[char] = Set[t]
          unless find_state(dfa_states, data)
            dfa_states.add(t)
            stack.push(t)
          end
        end
      end

      DFA.new(
        initial:  dfa_initial,
        terminal: dfa_terminal,
        alphabet: alphabet,
        states:   dfa_states
      )
    end

    def epsilon_closure(set_of_states)
      the_epsilon_closure = Set.new
      set_of_states.each do |state|
        the_epsilon_closure.merge(state.epsilon_closure)
      end
      the_epsilon_closure
    end

    def neighbors(set_of_states, char)
      the_neighbors = Set.new
      set_of_states.each do |state|
        the_neighbors.merge(state.moves[char]) if state.moves[char]
      end
      the_neighbors
    end

    def find_state(dfa_states, data)
      dfa_states.find { |state| state.data == data }
    end
  end

  class Automaton
    include FromAST
    include ToDFA

    attr_accessor :initial
    attr_accessor :terminal
    attr_writer   :alphabet

    def initialize(initial: nil, terminal: nil, alphabet: nil, states: nil)
      @initial  = initial
      @terminal = terminal
      @alphabet = alphabet
      @states   = states
    end

    def alphabet
      @alphabet ||= compute_alphabet
    end

    # if @alphabet has not been set, compute it on the fly
    def compute_alphabet
      chars = Set.new

      states.each do |state|
        chars.merge(Set[*state.moves.keys])
      end

      Set[*chars.reject { |char| char == '' }]
    end

    # if @states has not been set, compute it on the fly
    def states
      @states ||= compute_states
    end

    def compute_states
      @initial.reachable
    end

    def to_s
      label_all_states
      transitions = states.map(&:transition_string).compact.join("\n")
      "states: #{states}" \
        "\ninitial: #{initial}" \
        "\nterminal: #{terminal}" \
        "\nalphabet: #{alphabet}" \
        "\ntransitions:\n#{transitions}"
    end

    def label_all_states # for pretty printout
      index = 0

      states.each do |state|
        state.label = "q#{index}"
        index += 1
      end
    end
  end

  class DFA < Automaton
    def accept?(line, from, to, state = initial)
      return false if from > (to + 1)
      return true if from == (to + 1) && terminal.include?(state)

      if state.moves['\^']
        return true if from == 0 &&
          accept?(line, from, to, state.moves['\^'].elem)
      end

      if state.moves['\$']
        return true if from == line.length - 1 &&
          accept?(line, from, to, state.moves['\$'].elem)
      end

      if state.moves[line[from]]
        return true if accept?(line, from + 1, to, state.moves[line[from]].elem)
      end

      nil
    end
  end

  class Engine
    def initialize(pattern, path, substitution = nil)
      @pattern      = pattern
      @path         = path
      @substitution = substitution
      @line_index   = 0
    end

    def search
      @file = File.open(@path)

      while line = @file.gets
        @line_index += 1
        next unless indices = match(line)
        from, to = indices
        pre_match = line[0...from]
        match = line[from..to].colorize(:light_green).underline
        # ^ TODO: make match highlighting smart
        post_match = line[to + 1...line.length]
        puts "#{pad(@line_index)}:  " + pre_match + match + post_match
      end

      @file.close
    end

    def replace
      @file = File.open(@path)

      while line = @file.gets
        @line_index += 1
        if indices = match(line)
          from, to = indices
          pre_match = line[0...from]
          post_match = line[to + 1...line.length]
          sub = @substitution.colorize(:light_green).underline
          # ^ TODO: make match highlighting smart
          puts pre_match + sub + post_match
        else
          puts line
        end
      end

      @file.close
    end

    # todo: refactor for readability
    # https://stackoverflow.com/questions/2650517
    def pad(number)
      line_count = %x{wc -l #{@path}}.split.first
      format("%0#{line_count.length}d", number.to_s)
    end

    # favours matches that start earlier
    # among those, favours long matches
    # Unfortunately, this is O(n2)
    def match(line)
      0.upto(line.length - 1) do |from|
        (line.length - 1).downto(from) do |to|
          return [from, to] if automaton.accept?(line, from, to)
        end
      end
      nil
    end

    def automaton
      @automaton ||= Parser.new(@pattern).parse.to_automaton.to_dfa
    end
  end

  class CLI
    def self.run
      case ARGV.shift
      when 'search'
        pattern = ARGV.shift
        path = ARGV.shift
        engine = Engine.new(pattern, path)
        engine.search
      when 'sub'
        pattern = ARGV.shift
        substitution = ARGV.shift
        path = ARGV.shift
        engine = Engine.new(pattern, path, substitution)
        engine.replace
      end
    end
  end
end
