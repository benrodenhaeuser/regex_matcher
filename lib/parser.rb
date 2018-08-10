require_relative './token.rb'
require_relative './tokenizer.rb'
require_relative './ast.rb'

module Rex
  class Parser
    attr_reader :lookahead

    def initialize(source)
      @tokenizer = Tokenizer.new(source)
      consume
    end

    def match(expected_type)
      return consume if lookahead.type == expected_type
      raise "Mismatch! Expected #{expected_type}, saw #{lookahead.type}"
    end

    def consume
      @lookahead = @tokenizer.next_token
    end

    def eof?
      lookahead.type == Tokenizer::EOF_TYPE
    end

    def parse
      ast = regex
      raise 'Expected end of stream' unless eof?
      ast
    end

    def regex
      left_ast = term
      if lookahead.type == Tokenizer::ALTERNATE
        token = lookahead
        match(Tokenizer::ALTERNATE)
        right_ast = regex
      end

      return left_ast unless right_ast
      AST.new(root: token, left: left_ast, right: right_ast)
    end

    def term
      factor_first = [
        Tokenizer::CHAR,
        Tokenizer::DOT,
        Tokenizer::LPAREN
      ]

      ast = factor
      return ast unless factor_first.include?(lookahead.type)
      token = Token.new(Tokenizer::CONCAT, '')
      AST.new(root: token, left: ast, right: term)
    end

    def factor
      ast = base
      return ast unless lookahead.type == Tokenizer::STAR
      token = lookahead
      match(Tokenizer::STAR)
      AST.new(root: token, left: ast)
    end

    def base
      atomic_expressions = [
        Tokenizer::CHAR,
        Tokenizer::DOT
      ]

      type = lookahead.type

      if atomic_expressions.include?(type)
        atom
      elsif type == Tokenizer::LPAREN
        match(Tokenizer::LPAREN)
        ast = regex
        match(Tokenizer::RPAREN)
        ast
      end
    end

    def atom
      token = lookahead
      match(token.type)
      AST.new(root: token)
    end
  end
end
