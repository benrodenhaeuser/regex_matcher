require 'minitest/autorun'

require_relative '../lib/application.rb'

TEST_DEFAULTS = {
  line_numbers:           false,
  one_match_per_line:     false,
  all_lines:              false,
  matching_segments_only: true,
  substitution:           nil
}.freeze

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

    actual = tokenizer.next_token.type
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

class EngineTest < Minitest::Test
  def setup
    path_to_current_dir = File.expand_path(File.dirname(__FILE__))
    @data_path = File.join(path_to_current_dir, 'data')
    Dir.mkdir(@data_path) unless Dir.exist?(@data_path)

    @inp_path = File.join(@data_path, 'input.txt')
    @out_path = File.join(@data_path, 'output.txt')
  end

  def app(pattern, opts = {})
    Rex::Application.new(
      pattern:      pattern,
      inp_path:     @inp_path,
      out_path:     @out_path,
      user_options: TEST_DEFAULTS.merge(opts)
    )
  end

  def output(pattern:, text:, opts: {})
    write_to_input_file(text)
    app(pattern, opts).run
    read_from_output_file
  end

  # write string we want to test against
  def write_to_input_file(text)
    File.write(@inp_path, text)
  end

  # read output produced by engine
  def read_from_output_file
    File.read(@out_path)
  end

  def test_literal_concatenation
    actual = output(
      pattern: 'test',
      text: 'test abcd test abcd'
    )
    expected = "test, test\n"

    assert_equal(expected, actual)
  end

  def test_one_match_mode
    user_options = { one_match_per_line: true }

    actual = output(
      pattern: 'test',
      text: 'test abcd test abcd',
      opts: user_options
    )
    expected = "test\n"

    assert_equal(expected, actual)
  end

  def test_line_numbers
    user_options = { line_numbers: true }

    actual = output(
      pattern: 'test',
      text: 'test abcd test abcd',
      opts: user_options
    )
    expected = "1: test, test\n"

    assert_equal(expected, actual)
  end

  def test_alternation
    actual = output(
      pattern: 'man|park',
      text: 'a man is walking in the park.'
    )
    expected = "man, park\n"

    assert_equal(expected, actual)
  end

  def test_star
    actual = output(
      pattern: '(a|b)*',
      text: 'aaabbbcccab'
    )
    expected = "aaabbb, ab\n"

    assert_equal(expected, actual)
  end

  def test_option1
    actual = output(
      pattern: 'a?',
      text: 'a'
    )
    expected = "a\n"

    assert_equal(expected, actual)
  end

  def test_option2
    actual = output(
      pattern: 'a?',
      text: 'b'
    )
    expected = "\n"

    assert_equal(expected, actual)
  end

  def test_option3
    actual = output(
      pattern: 'colou?r',
      text: 'colour'
    )
    expected = "colour\n"

    assert_equal(expected, actual)
  end

  def test_option4
    actual = output(
      pattern: 'colou?r',
      text: 'color'
    )
    expected = "color\n"

    assert_equal(expected, actual)
  end

  def test_dot
    actual = output(
      pattern: '.',
      text: 'aaabbb'
    )
    expected = "a, a, a, b, b, b\n"

    assert_equal(expected, actual)
  end

  def test_dot_star
    actual = output(
      pattern: '.*',
      text: 'aaabbb'
    )
    expected = "aaabbb\n"

    assert_equal(expected, actual)
  end

  def test_slightly_more_complicated_regex
    actual = output(
      pattern: '(a|b)*(a|b)',
      text: 'aaabbba'
    )
    expected = "aaabbba\n"

    assert_equal(expected, actual)
  end

  def test_multiline_input
    input = <<~HEREDOC
      aaabb
      bbbccc
    HEREDOC
    actual = output(
      pattern: 'aaa|ccc',
      text: input
    )
    expected = <<~HEREDOC
      aaa
      ccc
    HEREDOC
    expected = expected
    assert_equal(expected, actual)
  end

  def teardown
    File.delete(@inp_path) if File.exist?(@inp_path)
    File.delete(@out_path) if File.exist?(@out_path)
    Dir.delete(@data_path)
  end
end
