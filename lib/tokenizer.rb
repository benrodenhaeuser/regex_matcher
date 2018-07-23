module Rex
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
    end

    def next_token
      consume while white_space
      return Token.new(EOF_TYPE, '<eof>') if @cursor == EOF

      character = @cursor
      consume

      case character
      when '('
        Token.new(LPAREN, character)
      when ')'
        Token.new(RPAREN, character)
      when '*'
        Token.new(STAR, character)
      when '|'
        Token.new(ALTERNATE, character)
      when *ALPHABET
        Token.new(ALPHANUMERIC, character)
      else
        raise "Invalid character '#{character}'"
      end
    end

    def consume
      @position += 1
      @cursor = (@position < @source.length ? @source[@position] : EOF)
    end

    def white_space
      [' ', '\n'].include?(@cursor)
    end
  end
end
