# source: https://lukaszwrobel.pl/blog/math-parser-part-3-implementation/
# (a blog post series by Lukasz Wrobel)

# number     = {"0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"}
# factor     = number | "(" expression ")"
# component  = factor [{("*" | "/") factor}]
# expression = component [{("+" | "-") component}]

class Token
  PLUS = 0
  MINUS = 1
  MULTIPLY = 2
  DIVIDE = 3
  NUMBER = 4
  LPAREN = 5
  RPAREN = 6
  ENDOFINPUT = 7

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

class Lexer
  def initialize(input)
    @input = input
    @return_previous_token = false
  end

  def get_next_token
    if @return_previous_token
      @return_previous_token = false
      return @previous_token
    end

    token = Token.new

    @input.lstrip!

    case @input
    when /\A\+/
      token.kind = Token::PLUS
    when /\A-/
      token.kind = Token::MINUS
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
      token.kind = Token::ENDOFINPUT
    end

    raise 'Unknown token' if token.unknown?
    @input = $'  # $' is the string to the right of the last successful match.

    @previous_token = token
    token
  end

  def revert
    @return_previous_token = true
  end
end

class Parser
  def parse(input)
    @lexer = Lexer.new(input)

    expression_value = expression

    token = @lexer.get_next_token

    if token.kind == Token::ENDOFINPUT
      expression_value
    else
      raise 'End expected'
    end
  end

  def expression
    component1 = factor # call factor method

    additive_operators = [Token::PLUS, Token::MINUS]

    token = @lexer.get_next_token

    while additive_operators.include?(token.kind)
      component2 = factor # call factor method

      if token.kind == Token::PLUS
        component1 += component2
      else
        component1 -= component2
      end

      token = @lexer.get_next_token
    end

    @lexer.revert

    component1
  end

  def factor
    factor1 = number # call number method

    multiplicative_operators = [Token::MULTIPLY, Token::DIVIDE]

    token = @lexer.get_next_token
    while multiplicative_operators.include?(token.kind)
      factor2 = number

      if token.kind == Token::MULTIPLY
        factor1 *= factor2
      else
        factor1 /= factor2
      end

      token = @lexer.get_next_token
    end

    @lexer.revert

    factor1
  end

  def number
    token = @lexer.get_next_token

    if token.kind == Token::LPAREN
      value = expression # call expression method

      expected_rparen = @lexer.get_next_token
      raise 'Unbalanced parenthesis' unless expected_rparen.kind == Token::RPAREN
    elsif token.kind == Token::NUMBER
      value = token.value
    else
      raise 'Not a number'
    end

    value
  end
end

parser = Parser.new

loop do
  begin
    print '>> '
    puts parser.parse(gets)
  rescue RuntimeError
    puts 'Error occurred: ' + $! # $! is the exception info message set by last raise
  end
end
