module Rex
  ALPHABET = [
    'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l',
    'm', 'n', 'o', 'p', 'q', 'r',
    's', 't', 'u', 'v', 'w', 'x',
    'y', 'z',
    'A', 'B', 'C', 'D', 'E', 'F',
    'G', 'H', 'I', 'J', 'K', 'L',
    'M', 'N', 'O', 'P', 'Q', 'R',
    'S', 'T', 'U', 'V', 'W', 'X',
    'Y', 'Z'
  ]

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
    ALPHANUMERIC = 2
    CONCATENATE = 3
    ALTERNATE = 4
    STAR = 5
    LPAREN = 6
    RPAREN = 7

    attr_reader :cursor

    def initialize(source)
      @source = source
      @position = 0
      @cursor = @source[@position]
      @token = Token.new(START_TYPE, '')
    end

    def consume
      @position += 1
      @cursor = (@position < @source.length ? @source[@position] : EOF)
    end

    def match(character)
      if @cursor == character
        consume
      else
        raise "Mismatch! Expected #{character}, saw #{@cursor}"
      end
    end

    def next_token
      consume while white_space

      @token =
        case @cursor
        when EOF
          Token.new(EOF_TYPE, '<eof>')
        when '('
          consume
          Token.new(LPAREN, '(')
        when ')'
          consume
          Token.new(RPAREN, ')')
        when '*'
          consume
          Token.new(STAR, '*')
        when '|'
          consume
          Token.new(ALTERNATE, '|')
        when *ALPHABET
          if @token.type == ALPHANUMERIC
            Token.new(CONCATENATE, '')
          else
            char = @cursor
            consume
            Token.new(ALPHANUMERIC, char)
          end
        else
          raise "Invalid character '#{@cursor}'"
        end
    end

    def white_space
      [' ', '\n'].include?(@cursor)
    end
  end

  class Parser
    attr_reader :lookahead

    def initialize(tokenizer)
      @tokenizer = tokenizer
      consume
    end

    def match(expected_type)
      if lookahead.type == expected_type
        consume
      else
        raise "Mismatch! Expected #{expected_type}, saw #{lookahead.type}"
      end
    end

    def consume
      @lookahead = @tokenizer.next_token
    end

    def eof?
      lookahead.type == Tokenizer::EOF_TYPE
    end

    def parse
      value = regex
      raise "Expected end of stream" unless eof?
      value
    end

    def regex
      left_value = term
      if lookahead.type == Tokenizer::ALTERNATE
        match(Tokenizer::ALTERNATE)
        right_value = regex
      end

      return left_value unless right_value
      left_value.alternate(right_value)
    end

    def term
      values = []
      loop do
        values << factor
        break unless lookahead.type == Tokenizer::CONCATENATE
        match(Tokenizer::CONCATENATE)
      end

      values.reduce { |memo, factor| memo.concatenate(factor) }
    end

    def factor
      value = base
      if lookahead.type == Tokenizer::STAR
        match(Tokenizer::STAR)
        value.iterate
      else
        value
      end
    end

    def base
      if lookahead.type == Tokenizer::ALPHANUMERIC
        char = lookahead.text
        match(Tokenizer::ALPHANUMERIC)
        Automaton.from_char(char)
      elsif lookahead.type == Tokenizer::LPAREN
        match(Tokenizer::LPAREN)
        value = regex
        match(Tokenizer::RPAREN)
        value
      end
    end
  end
end
