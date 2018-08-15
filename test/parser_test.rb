require 'minitest/autorun'

require_relative '../lib/rex_cli/parser.rb'

class TokenizerText < Minitest::Test
  def test_escaped_star_is_tokenized_as_char
    tokenizer = Rex::Tokenizer.new('\*')
    actual = tokenizer.next_token.type
    expected = Rex::Tokenizer::CHAR
    assert_equal(expected, actual)
  end

  def test_end_of_input_is_tokenized_as_eof_token
    tokenizer = Rex::Tokenizer.new('a')
    tokenizer.next_token # process 'a'
    actual = tokenizer.next_token.type
    expected = Rex::Tokenizer::EOF_TYPE
    assert_equal(expected, actual)
    # still eof after another read:
    actual = tokenizer.next_token.type
    assert_equal(expected, actual)
  end

  def tokenize_esaped_char
    tokenizer = Rex::Tokenizer.new('\(')
    token = tokenizer.next_token
    actual = token.type
    expected = Rex::Tokenizer::CHAR
    assert_equal(expected, actual)
    actual = token.text
    expected = '('
    assert_equal(expected, actual)
  end
end

class ParserTest < Minitest::Test
  def test_unbalanced_parentheses_raise_exception1
    parser = Rex::Parser.new("(a|b|(c|d)")
    assert_raises(Rex::RegexError) { parser.parse }
  end

  def test_unbalanced_parentheses_raise_exception2
    parser = Rex::Parser.new("a)")
    assert_raises(Rex::RegexError) { parser.parse }
  end

  def test_empty_subexpression_raises_exception1
    parser = Rex::Parser.new("a|")
    assert_raises(Rex::RegexError) { parser.parse }
  end

  def test_empty_subexpression_raises_exception2
    parser = Rex::Parser.new("(*)|ab")
    assert_raises(Rex::RegexError) { parser.parse }
  end
end
