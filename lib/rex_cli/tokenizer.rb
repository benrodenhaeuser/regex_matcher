module Rex
  ALPHABET = (32..126).map { |int| int.chr(Encoding::ASCII) }
  # ^ "Basic Latin" character set
  #   see https://en.wikipedia.org/wiki/List_of_Unicode_characters#Basic_Latin

  ESCAPED = %w(* + ( ) ? . |)
  # ^ Characters that need to be preceded with backslash for use as literals

  class TokenError < RuntimeError; end

  class Tokenizer
    EOF        = -1
    START_TYPE = 0
    EOF_TYPE   = 1
    CHAR       = 2
    DOT        = 3
    CONCAT     = 4
    ALTERNATE  = 5
    STAR       = 6
    OPTION     = 7
    LPAREN     = 8
    RPAREN     = 9

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
        when '?'
          Token.new(OPTION, @cursor)
        when '|'
          Token.new(ALTERNATE, @cursor)
        when '.'
          Token.new(DOT, @cursor)
        when BACKSLASH
          consume
          unless ESCAPED.include?(@cursor)
            raise TokenError, "illegal: #{@cursor}"
          end
          Token.new(CHAR, @cursor)
        else
          unless ALPHABET.include?(@cursor)
            raise TokenError, "illegal: #{@cursor}"
          end
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
end
