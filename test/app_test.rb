require 'minitest/autorun'

require_relative '../lib/application.rb'

TEST_DEFAULTS = {
  line_numbers: false,
  global:       true,
  all_lines:    false,
  only_matches: true,
  highlight:    false
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

class AppTest < Minitest::Test
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

  def test_concatenation_of_literals
    # skip
    actual = output(
      pattern: 'test',
      text: 'test abcd test abcd'
    )
    expected = "test\ntest\n"

    assert_equal(expected, actual)
  end

  def test_one_match_mode
    # skip
    user_options = { global: false }

    actual = output(
      pattern: 'test',
      text: 'test abcd test abcd',
      opts: user_options
    )
    expected = "test\n"

    assert_equal(expected, actual)
  end

  def test_alternation
    # skip
    actual = output(
      pattern: 'man|park',
      text: 'a man is walking in the park.'
    )
    expected = "man\npark\n"

    assert_equal(expected, actual)
  end

  def test_star
    # skip
    actual = output(
      pattern: '(a|b)*',
      text: 'aaabbbcccab'
    )
    expected = <<~HEREDOC
      aaabbb



      ab
    HEREDOC
    # ^ we choose to output empty matches. there are three here.

    assert_equal(expected, actual)
  end

  def test_option1
    # skip
    actual = output(
      pattern: 'a?',
      text: 'a'
    )
    expected = "a\n"

    assert_equal(expected, actual)
  end

  def test_option2
    # skip
    actual = output(
      pattern: 'a?',
      text: 'b'
    )
    expected = "\n"

    assert_equal(expected, actual)
  end

  def test_option3
    # skip
    actual = output(
      pattern: 'colou?r',
      text: 'colour'
    )
    expected = "colour\n"

    assert_equal(expected, actual)
  end

  def test_option4
    # skip
    actual = output(
      pattern: 'colou?r',
      text: 'color'
    )
    expected = "color\n"

    assert_equal(expected, actual)
  end

  def test_dot
    # skip
    actual = output(
      pattern: '.',
      text: 'aaabbb'
    )
    expected = ["a\n", "a\n", "a\n", "b\n", "b\n", "b\n"].join

    assert_equal(expected, actual)
  end

  def test_dot_star
    # skip
    actual = output(
      pattern: '.*',
      text: 'aaabbb'
    )
    expected = "aaabbb\n"

    assert_equal(expected, actual)
  end

  def test_slightly_more_complicated_regex
    # skip
    actual = output(
      pattern: '(a|b)*(a|b)',
      text: 'aaabbba'
    )
    expected = "aaabbba\n"

    assert_equal(expected, actual)
  end

  def test_multiline_input
    # skip
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
    assert_equal(expected, actual)
  end

  def test_with_line_numbers_and_full_line_output
    # skip
    user_options = {
      line_numbers: true,
      only_matches: false
    }

    input = <<~HEREDOC
      first line
      second line
      third line
    HEREDOC
    actual = output(
      pattern: 'second',
      text: input,
      opts: user_options
    )
    expected = <<~HEREDOC
      2: second line
    HEREDOC
    assert_equal(expected, actual)
  end

  def test_with_full_line_output
    # skip
    user_options = {
      only_matches: false
    }

    input = <<~HEREDOC
      first line
      second line
      third line
    HEREDOC
    actual = output(
      pattern: 'second',
      text: input,
      opts: user_options
    )
    expected = <<~HEREDOC
      second line
    HEREDOC
    assert_equal(expected, actual)
  end

  def test_with_line_numbers
    # skip
    user_options = { line_numbers: true }

    actual = output(
      pattern: 'test',
      text: 'test abcd test abcd',
      opts: user_options
    )
    expected = <<~HEREDOC
      1:1: test
      1:11: test
    HEREDOC
    assert_equal(expected, actual)
  end

  def test_highlighting1
    user_options = { highlight: true }
    actual = output(
      pattern: 'test',
      text: 'test',
      opts: user_options
    )
    expected = "\e[4m\e[31mtest\e[0m\e[0m\n"
    # ^ to verify this is what we need:
    # `$ echo -e "\e[4m\e[31mtest\e[0m\e[0m\n"`
    # (the `-e` switch is to interpret escape characters)
    assert_equal(expected, actual)
  end

  def test_highlighting2
    user_options = {
      highlight: true,
      only_matches: false
    }
    actual = output(
      pattern: 'test',
      text: 'somestuffandtestandmorestuff',
      opts: user_options
    )
    expected = "somestuffand\e[4m\e[31mtest\e[0m\e[0mandmorestuff\n"
    assert_equal(expected, actual)
  end

  def teardown
    File.delete(@inp_path) if File.exist?(@inp_path)
    File.delete(@out_path) if File.exist?(@out_path)
    Dir.delete(@data_path)
  end
end
