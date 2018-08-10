require 'minitest/autorun'

require_relative '../lib/engine.rb'

TEST_DEFAULTS = {
  line_numbers:           false,
  one_match_per_line:     false,
  all_lines:              false,
  matching_segments_only: true,
  substitution:           nil
}.freeze

class EngineTest < Minitest::Test
  def setup
    path_to_current_dir = File.expand_path(File.dirname(__FILE__))
    @data_path = File.join(path_to_current_dir, 'data')
    Dir.mkdir(@data_path)

    @in_path = File.join(@data_path, 'input.txt')
    @out_path = File.join(@data_path, 'output.txt')
  end

  def engine(pattern, opts = {})
    Rex::Engine.new(
      pattern:      pattern,
      in_path:      @in_path,
      out_path:     @out_path,
      user_options: TEST_DEFAULTS.merge(opts)
    )
  end

  def write_to_input_file(text)
    File.write(@in_path, text)
  end

  def read_from_output_file
    File.read(@out_path).chomp
  end

  def output(pattern:, text:, opts: {})
    write_to_input_file(text)
    engine(pattern, opts).run
    read_from_output_file
  end

  def test_literal_concatenation
    actual = output(
      pattern: 'test',
      text: 'test abcd test abcd'
    )
    expected = "test, test"

    assert_equal(expected, actual)
  end

  def test_one_match_mode
    user_options = { one_match_per_line: true }

    actual = output(
      pattern: 'test',
      text: 'test abcd test abcd',
      opts: user_options
    )
    expected = "test"

    assert_equal(expected, actual)
  end

  def test_line_numbers
    user_options = { line_numbers: true }

    actual = output(
      pattern: 'test',
      text: 'test abcd test abcd',
      opts: user_options
    )
    expected = "1: test, test"

    assert_equal(expected, actual)
  end

  def test_alternation
    actual = output(
      pattern: 'man|park',
      text: 'a man is walking in the park.'
    )
    expected = "man, park"

    assert_equal(expected, actual)
  end

  def test_star
    actual = output(
      pattern: '(a|b)*',
      text: 'aaabbbcccab'
    )
    expected = "aaabbb, ab"

    assert_equal(expected, actual)
  end

  def test_dot
    actual = output(
      pattern: '.',
      text: 'aaabbb'
    )
    expected = "a, a, a, b, b, b"

    assert_equal(expected, actual)
  end

  def test_dot_star
    actual = output(
      pattern: '.*',
      text: 'aaabbb'
    )
    expected = "aaabbb"

    assert_equal(expected, actual)
  end

  def teardown
    File.delete(@in_path)
    File.delete(@out_path)
    Dir.delete(@data_path)
  end
end
