require_relative './token.rb'
require_relative './tokenizer.rb'
require_relative './ast.rb'

module Rex
  class RegexError < RuntimeError; end

  class Parser
    attr_reader :lookahead

    def initialize(source)
      @tokenizer = Tokenizer.new(source)
      consume
    end

    def parse
      ast = expression
      raise(RegexError, 'Expected end of stream') unless eof?
      ast
    end

    private

    def match(expected_type)
      return consume if lookahead.type == expected_type
      raise RegexError, "Expected #{expected_type}, saw #{lookahead.type}"
    end

    def consume
      @lookahead = @tokenizer.next_token
    end

    def eof?
      lookahead.type == Tokenizer::EOF_TYPE
    end

    def expression
      left_ast = term
      if lookahead.type == Tokenizer::ALTERNATE
        token = lookahead
        match(Tokenizer::ALTERNATE)
        right_ast = expression
      end
      return left_ast unless right_ast
      AST.new(root: token, left: left_ast, right: right_ast)
    end

    def term
      ast = factor
      factor_first = [Tokenizer::CHAR, Tokenizer::DOT, Tokenizer::LPAREN]
      return ast unless factor_first.include?(lookahead.type)
      token = Token.new(Tokenizer::CONCAT, '')
      AST.new(root: token, left: ast, right: term)
    end

    def factor
      ast = base
      case lookahead.type
      when Tokenizer::STAR
        token = lookahead
        match(Tokenizer::STAR)
        AST.new(root: token, left: ast)
      when Tokenizer::OPTION
        token = lookahead
        match(Tokenizer::OPTION)
        AST.new(root: token, left: ast)
      else
        ast
      end
    end

    def base
      type = lookahead.type
      if [Tokenizer::CHAR, Tokenizer::DOT].include?(type)
        atom
      elsif type == Tokenizer::LPAREN
        match(Tokenizer::LPAREN)
        ast = expression
        match(Tokenizer::RPAREN)
        ast
      else
        raise RegexError, "Invalid regular expression"
      end
    end

    def atom
      token = lookahead
      match(token.type)
      AST.new(root: token)
    end
  end
end
