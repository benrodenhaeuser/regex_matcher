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
    CONCAT     = 4
    ALTERNATE  = 5
    STAR       = 6
    LPAREN     = 7
    RPAREN     = 8

    BACKSLASH = ' \ '.strip

    attr_reader :cursor

    def initialize(source)
      @source   = source
      @position = 0
      @cursor   = @source[@position]
    end

    def next_token
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
end
