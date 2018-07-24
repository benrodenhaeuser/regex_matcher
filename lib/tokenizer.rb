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
    ANYSINGLECHAR = 8

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
          Token.new(ANYSINGLECHAR, @cursor)
        when *ALPHABET
          Token.new(ALPHANUMERIC, @cursor)
        else
          raise "Invalid character '#{@cursor}'"
        end

      consume
      token
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
