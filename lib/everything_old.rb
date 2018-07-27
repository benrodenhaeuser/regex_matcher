require 'colorize'
require 'set'

class Set
  def singleton?
    size == 1
  end

  def unique_member
    raise 'Not a singleton!' unless singleton?
    to_a.first
  end

  def nonempty?
    !empty?
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
    attr_reader :type, :text

    def initialize(type, text)
      @type = type
      @text = text
    end
  end

  class Tokenizer
    EOF = -1
    START_TYPE = 0
    EOF_TYPE = 1
    CHAR = 2
    DOT = 3
    CONCAT = 4
    ALTERNATE = 5
    STAR = 6
    LPAREN = 7
    RPAREN = 8

    BACKSLASH = ' \ '.strip

    attr_reader :cursor

    def initialize(source)
      @source = source
      @position = 0
      @cursor = @source[@position]
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

    # TODO: take into account other kinds of whitespace?
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
      factor_first = [Tokenizer::CHAR, Tokenizer::LPAREN]

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

    def base
      case lookahead.type
      when Tokenizer::CHAR
        token = lookahead
        match(Tokenizer::CHAR)
        AST.new(root: token)
      when Tokenizer::DOT
        token = lookahead
        match(Tokenizer::DOT)
        AST.new(root: token)
      when Tokenizer::LPAREN
        match(Tokenizer::LPAREN)
        ast = regex
        match(Tokenizer::RPAREN)
        ast
      end
    end
  end

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

  module Thompson
    SILENT = ''

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def for_char(char)
        start = State.new
        accept_state = State.new
        start.moves[char] = Set[accept_state]
        new(start: start, accept: Set[accept_state], alphabet: Set[char])
      end

      def for_dot
        start = State.new
        accept_state = State.new
        ALPHABET.each { |char| start.moves[char] = Set[accept_state] }
        new(start: start, accept: Set[accept_state], alphabet: Set[*ALPHABET])
      end

      def from_ast(ast)
        case ast.root.type
        when Tokenizer::CHAR
          Automaton.for_char(ast.root.text)
        when Tokenizer::DOT
          Automaton.for_dot
        when Tokenizer::ALTERNATE
          ast.left.to_automaton.alternate(ast.right.to_automaton)
        when Tokenizer::CONCAT
          ast.left.to_automaton.concat(ast.right.to_automaton)
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
      alphabet.merge(other.alphabet)
      self
    end

    def concat(other)
      accept.unique_member.moves[SILENT] = Set[other.start]
      self.accept = other.accept
      alphabet.merge(other.alphabet)
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

  # TODO: refactor
  module DFA
    def to_dfa
      dfa_start = State.new(data: epsilon_closure(Set[start]))
      dfa_accept = Set.new

      dfa_states = Set[dfa_start]
      stack = [dfa_start]

      until stack.empty?
        q = stack.pop

        if q.data.any? { |substate| accept.include?(substate) }
          dfa_accept.add(q)
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

  class Automaton
    include Thompson
    include DFA

    attr_accessor :start, :accept
    attr_writer :alphabet

    def initialize(start: nil, accept: nil, alphabet: nil)
      @start = start
      @accept = accept
      @alphabet = alphabet
    end

    def alphabet
      @alphabet ||= compute_alphabet
    end

    def compute_alphabet
      chars = Set.new

      state_space.each do |state|
        chars.merge(Set[*state.moves.keys])
      end

      Set[*chars.reject { |char| char == '' }]
    end

    def accept?(string)
      current = start
      string.each_char do |char|
        return false if current.moves[char].empty?
        current = current.moves[char].unique_member
      end
      accept.include?(current)
    end

    # TODO: keep track of this via an ivar?
    def state_space
      @start.reachable
    end

    def to_s
      label_all_states
      transitions = state_space.map(&:transition_string).join("\n")
      "start: #{start}" \
        "\naccept: #{accept}" \
        "\ntransitions:\n#{transitions}"
    end

    def label_all_states # for pretty printout
      index = 0

      state_space.each do |state|
        state.label = "q#{index}"
        index += 1
      end
    end
  end

  class Matcher
    def initialize(pattern: nil, path: nil)
      @pattern = pattern
      @path = path
    end

    def matches
      @file = File.open(@path)

      while line = @file.gets
        next unless indices = match_indices(line)
        from, to = indices
        pre_match = line[0...from]
        match = line[from..to].colorize(:light_green).underline.bold
        post_match = line[to + 1...line.length]
        (matches ||= []) << pre_match + match + post_match
      end

      @file.close
      matches
    end

    def match_indices(line)
      0.upto(line.length - 1) do |from|
        (line.length - 1).downto(from) do |to|
          segment = line[from..to]
          return [from, to] if automaton.accept?(segment)
        end
      end
      nil
    end

    def automaton
      @automaton ||= Parser.new(@pattern).parse.to_automaton.to_dfa
    end
  end

  class CLI
    class << self
      def run
        return puts help_message unless ARGV[0] && ARGV[1]
        matcher = Matcher.new(pattern: ARGV.shift, path: ARGV.shift)
        matcher.matches.each { |match| puts match }
      end

      def help_message
        'You must provide a pattern and a path.'
      end
    end
  end
end
