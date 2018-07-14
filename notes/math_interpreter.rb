# num = {"0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"}
# exp = num | (op)
# op  = exp + exp | exp * exp | exp / exp | exp - exp

# note that we don't have to handle precedence issues because all operations are bracketed!

class Token
  ADD = 0
  SUBTRACT = 1
  MULTIPLY = 2
  DIVIDE = 3
  NUMBER = 4
  LPAREN = 5
  RPAREN = 6
  EOF = -1 # right?

  attr_accessor :kind
  attr_accessor :value

  def initialize
    @kind = nil
    @value = nil
  end

  def unknown?
    @kind.nil?
  end
end

class Scanner
  def initialize(input)
    @input = input
  end

  def next_token
    @input.lstrip!

    token = Token.new

    case @input
    when /\A\+/
      token.kind = Token::ADD
    when /\A-/
      token.kind = Token::SUBTRACT
    when /\A\*/
      token.kind = Token::MULTIPLY
    when /\A\//
      token.kind = Token::DIVIDE
    when /\A\d+/
      token.kind = Token::NUMBER
      token.value = $&.to_i # $& is the last match.
    when /\A\(/
      token.kind = Token::LPAREN
    when /\A\)/
      token.kind = Token::RPAREN
    when ''
      token.kind = Token::EOF
    end

    @input = $' # $' is the string to the right of last succesful match.

    token
  end
end

class Parser
  def parse(input)
    @scanner = Scanner.new(input)
    @token = nil
    result = expression

    if @scanner.next_token.kind == Token::EOF
      result
    else
      raise 'Expected end of stream.'
    end
  end

  def expression
    @token = @scanner.next_token

    case @token.kind
    when Token::NUMBER
      value = number
    when Token::LPAREN
      value = operation
      @token = @scanner.next_token
      raise 'Unbalanced parens' unless @token.kind == Token::RPAREN
    end

    value
  end

  def operation
    value = expression
    @token = @scanner.next_token

    case @token.kind
    when Token::ADD
      value += expression
    when Token::SUBTRACT
      value -= expression
    when Token::MULTIPLY
      value *= expression
    when Token::DIVIDE
      value /= expression
    end

    value
  end

  def number
    @token.value
  end
end

parser = Parser.new
puts parser.parse("(10 + (5 + 4))") == 19
puts parser.parse("(((10 + (5 * 4)) / 10) - 3)") == 0
puts parser.parse("(10+ 4)") == 14

# puts parser.parse("(10+4).") # "expected end of stream"
# puts parser.parse("((10+4))") # Can't handle it
# puts parser.parse("(10+4") # Unbalanced parens - fine

# associativity
# a + b + c ~ (a + b) + c
# precedence
# a + b * c ~ a + (b * c)
