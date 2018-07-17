module Rex
  class Token
    attr_reader :type, :token

    def initialize(type, text)
      @type = type
      @text = text
    end
  end

  class Scanner
    EOF = -1

    START_TYPE = 0
    EOF_TYPE = 1
    CHAR = 2
    CONCATENATE = 3
    ALTERNATE = 4
    STAR = 5
    LPAREN = 6
    RPAREN = 7

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
      if (@cursor == character)
        consume
      else
        raise "Mismatch, expected #{character}, saw #{@cursor}"
      end
    end

    def character?
      @cursor.match(/[A-Z]/i)
    end

    def next_token
      while @cursor != EOF
        case @cursor
        when ' ', "\t", "\n", "\r" then white_space

        when '('
          consume
          return @token = Token.new(LPAREN, '(')

        when ')'
          consume
          return @token = Token.new(RPAREN, ')')

        when '*'
          consume
          return @token = Token.new(STAR, '*')

        when '|'
          consume
          return @token = Token.new(ALTERNATE, '|')

        else
          if character?
            if @token.type == CHAR
              return @token = Token.new(CONCATENATE, '')
            else
              char = @cursor
              consume
              return @token = Token.new(CHAR, char)
            end
          else
            raise "Invalid character '#{@cursor}'"
          end
        end
      end

      Token.new(EOF_TYPE, '<eof>')
    end

    def white_space
      consume while [' ', "\t", "\n", "\r"].include? @cursor
    end
  end

  class Parser
    def self.parse(regex_source)
      # TODO
    end
  end
end
