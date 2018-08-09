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
    @test_dir = File.expand_path(File.dirname(__FILE__))

    @data_path = File.join(@test_dir, 'data')
    Dir.mkdir(@data_path)

    @in_path = File.join(@data_path, 'input.txt')
    @out_path = File.join(@data_path, 'output.txt')

    @input = File.new(@in_path, 'w').close
    @output = File.new(@out_path, 'w').close
  end

  def engine(pattern:, opts: {})
    Rex::Engine.new(
      pattern:      pattern,
      in_path:      @in_path,
      out_path:     @out_path,
      user_options: TEST_DEFAULTS.merge(opts)
    )
  end

  def test_engine
    # 1.) write text to input file

    # 2.) run engine with pattern
    engine(pattern: 'es').run

    # 3.) make assertions about output file
  end

  def teardown
    File.delete(@in_path)
    File.delete(@out_path)
    Dir.delete(@data_path)
  end
end
