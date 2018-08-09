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

  def test_literal_with_several_matches
    expected = output(pattern: 'test', text: 'test abcd test abcd')
    assert_equal(expected, "test, test")
  end

  def test_literal_with_several_matches_in_one_match_mode
    user_option = { one_match_per_line: true }
    expected = output(
      pattern: 'test',
      text: 'test abcd test abcd',
      opts: user_option
    )
    assert_equal(expected, "test")
  end


  def teardown
    File.delete(@in_path)
    File.delete(@out_path)
    Dir.delete(@data_path)
  end
end
