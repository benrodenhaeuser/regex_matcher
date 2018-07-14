# implement a LL(2) parser for the following grammar:

# list       : [ elements ]
# elements   : element (, element)*
# element    : NAME | list | assignment
# assignment : NAME = NAME

class Token
  attr_reader :type, :text

  def initialize(type, text)
    @type, @text = type, text
  end

  def to_s(lexer = nil)
    tname = lexer.nil? ? type : lexer.tname(type)

    "<'#{text}', #{tname}>"
  end

  alias_method :decode, :to_s
end

class Lexer
  EOF       = -1
  EOF_TYPE  = 1

  attr_reader :c # cursor

  def initialize(input)
    @input  = input
    @p      = 0         # Index into input
    @c      = input[@p]
  end

  def consume
    @p += 1
    @c = @p < @input.size ? @input[@p] : EOF
  end

  def match(ch)
    if @c == ch
      consume
    else
      fail "Expecting '#{ch}', found '#{c}"
    end
  end
end

class ListLexer < Lexer
  NAME    = 2
  COMMA   = 3
  LBRACK  = 4
  RBRACK  = 5
  EQUALS  = 6

  TOKEN_NAMES = ['Error', '<EOF>', 'NAME', 'COMMA', 'LBRACK', 'RBRACK', 'EQUALS']

  def self.tname(type)
    idx = (type >= TOKEN_NAMES.size ? 0 : type)
    "#{TOKEN_NAMES[idx]} (#{type})"
  end

  def letter?
    c.match(/[A-Za-z]/)
  end

  def next_token
    while c != EOF
      case c
      when ' ', "\t", "\n", "\r" then ws

      when ','
        consume
        return Token.new(COMMA, ',')

      when '['
        consume
        return Token.new(LBRACK, '[')

      when ']'
        consume
        return Token.new(RBRACK, ']')

      when '='
        consume
        return Token.new(EQUALS, '=')

      else
        return name if letter?
        fail "Invalid character '#{c}'"
      end
    end

    Token.new(EOF_TYPE, '<eof>')
  end

  def name
    ident = ''

    loop do
      ident << c
      consume
      break unless letter?
    end

    Token.new(NAME, ident)
  end

  def ws
    consume while [' ', "\t", "\n", "\r"].include? c
  end
end

class Parser
  attr_reader :lookahead

  def initialize(input, k)
    @input = input
    @lookahead = []
    @k     = k           # buffer size
    @p     = 0           # position

    @k.times { consume } # prime buffer

    # suppose @k is 3. then after priming the buffer, @p is 0 again (3 % 3)
    # and we have buffered 3 tokens.
  end 

  def lt(i)
    @lookahead[(@p + i - 1) % @k]
  end

  def la(i)
    lt(i).type
  end

  def consume
    @lookahead[@p] = @input.next_token
    @p = (@p + 1) % @k
  end

  def parse
    expression
    eof?
  end

  def match(expected_type)
    if la(1) == expected_type
      consume
    else
      fail "Expected #{@input.class.tname expected_type}, found: #{lookahead}"
    end
  end

  def eof?
    match ListLexer::EOF_TYPE
  end
end

class ListParser < Parser
  def expression
    list
  end

  def list
    match ListLexer::LBRACK
    elements
    match ListLexer::RBRACK
  end

  def elements
    element
    while la(1) == ListLexer::COMMA
      match ListLexer::COMMA
      element
    end
  end

  def element
    if la(1) == ListLexer::NAME && la(2) == ListLexer::EQUALS
      assignment
    elsif la(1) == ListLexer::NAME
      match ListLexer::NAME
    elsif la(1) == ListLexer::LBRACK
      list
    else
      fail "Expected name or list, found: #{lt(1)}"
    end
  end

  def assignment
    match ListLexer::NAME
    match ListLexer::EQUALS
    match ListLexer::NAME
  end
end

lexer = ListLexer.new('[a,b=c,,[d,e]]')
parser = ListParser.new(lexer, 3)
parser.parse

# puts parser.lookahead
# <'[', 4>
# <'a', 2>
# <',', 3>
# puts
# puts parser.lt(1) # <'[', 4>, i.e., the first lookahead token
# puts parser.la(1) # type 4, which is LBRACK
