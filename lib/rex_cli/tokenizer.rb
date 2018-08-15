module Rex
  ALPHABET = (32..126).map { |int| int.chr(Encoding::ASCII) }
  # ^ "Basic Latin" character set
  #   see https://en.wikipedia.org/wiki/List_of_Unicode_characters#Basic_Latin

  ESCAPED = %w(* + ( ) ? . |)
  # ^ Characters that need to be preceded with backslash to be used as literals

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
          raise "illegal char #{@cursor}" unless ESCAPED.include?(@cursor)
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
end
