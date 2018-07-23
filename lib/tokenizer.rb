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
end
