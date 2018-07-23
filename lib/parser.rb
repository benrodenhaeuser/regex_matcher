module Rex
  class Parser
    attr_reader :lookahead

    def initialize(source)
      @tokenizer = Tokenizer.new(source)
      consume
    end

    def match(expected_type)
      if lookahead.type == expected_type
        consume
      else
        raise "Mismatch! Expected #{expected_type}, saw #{lookahead.type}"
      end
    end

    def consume
      @lookahead = @tokenizer.next_token
    end

    def eof?
      lookahead.type == Tokenizer::EOF_TYPE
    end

    def parse
      value = regex
      raise "Expected end of stream" unless eof?
      value
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
      ast = factor
      term_first = [Tokenizer::ALPHANUMERIC, Tokenizer::LPAREN]
      return ast unless term_first.include?(lookahead.type)
      token = Token.new(Tokenizer::CONCATENATE, '')
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
      case lookahead.type
      when Tokenizer::ALPHANUMERIC
        token = lookahead
        match(Tokenizer::ALPHANUMERIC)
        AST.new(root: token)
      when Tokenizer::LPAREN
        match(Tokenizer::LPAREN)
        node = regex
        match(Tokenizer::RPAREN)
        node
      # TODO else clause to raise exception?
      end
    end
  end
end
