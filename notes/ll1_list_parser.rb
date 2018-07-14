# source: https://github.com/JulianNicholls/language-implementation-patterns
# (with small changes)
# (Ruby version of Language Implementation Patterns, chapter 01)

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

  # build identifier
  def name
    ident = ''

    loop do
      ident << c
      consume
      break unless letter?
    end

    Token.new(NAME, ident)
  end

  # throw away white space
  def ws
    consume while [' ', "\t", "\n", "\r"].include? c
  end
end

class Parser
  attr_reader :lookahead # the "current token" (already consumed)

  def initialize(input)
    @input      = input # a lexer instance
    consume # read the first token with next_token method
  end

  def parse # added this method as generic entry point
    expression
    eof? # check whether we are at EOF
  end

  # consume next token if lookahead type matches expected type
  # (e.g., "lists have to start with LBRACK")
  def match(expected_type)
    if lookahead.type == expected_type
      consume
    else
      fail "Expected #{@input.class.tname expected_type}, found: #{lookahead}"
      # tname is a class method!
    end
  end

  def consume
    @lookahead = @input.next_token
  end

  # added this method
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
    while lookahead.type == ListLexer::COMMA
      match ListLexer::COMMA
      element
    end
  end

  def element
    if lookahead.type == ListLexer::NAME
      match ListLexer::NAME
    elsif lookahead.type == ListLexer::LBRACK
      list
    else
      fail "Expected name or list, found: #{lookahead.decode(ListLexer)}"
    end
  end
end

lexer = ListLexer.new('[a, b, [c]]')
parser = ListParser.new(lexer)
parser.parse
