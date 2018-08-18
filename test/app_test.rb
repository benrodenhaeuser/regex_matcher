require 'minitest/autorun'

require_relative '../lib/rex_cli/application.rb'
require_relative '../lib/rex_cli/input.rb'

TEST_DEFAULTS = {
  line_numbers: false,
  global:       true,
  all_lines:    false,
  only_matches: true,
  color:    false
}.freeze

class ApplicationTest < Minitest::Test
  def setup
    path_to_current_dir = File.expand_path(File.dirname(__FILE__))
    @data_path = File.join(path_to_current_dir, 'data')
    Dir.mkdir(@data_path) unless Dir.exist?(@data_path)
    @inp_path = File.join(@data_path, 'input.txt')
  end

  def run_app!(pattern:, text: ,opts: {})
    File.write(@inp_path, text)

    options = TEST_DEFAULTS.merge(opts)

    Rex::Application.new(
      pattern:      pattern,
      input:        Rex::Input.new([@inp_path], options),
      user_options: options
    ).run!
  end

  def test_concatenation_of_literals
    # skip
    expected = "test\ntest\n"
    assert_output(expected) {
      run_app!(
        pattern: 'test',
        text: 'test abcd test abcd'
      )
    }
  end

  def test_one_match_mode
    # skip
    options = { global: false }

    expected = "test\n"
    assert_output(expected) {
      run_app!(
        pattern: 'test',
        text: 'test abcd test abcd',
        opts: options
      )
    }
  end

  def test_alternation
    # skip
    expected = "man\npark\n"
    assert_output(expected) {
      run_app!(
        pattern: 'man|park',
        text: 'a man is walking in the park.'
      )
    }
  end

  def test_star
    # skip
    expected = <<~HEREDOC
      aaabbb



      ab
    HEREDOC
    # ^ we output empty matches. there are three here, each
    #   corresponding to one 'c', so we have three empty lines.

    assert_output(expected) {
      run_app!(
        pattern: '(a|b)*',
        text: 'aaabbbcccab'
      )
    }
  end

  def test_option1
    # skip
    expected = "a\n"
    assert_output(expected) {
      run_app!(
        pattern: 'a?',
        text: 'a'
      )
    }
  end

  def test_option2
    # skip
    expected = "\n"
    assert_output(expected) {
      run_app!(
        pattern: 'a?',
        text: 'b'
      )
    }
  end

  def test_option3
    # skip
    expected = "colour\n"
    assert_output(expected) {
      run_app!(
        pattern: 'colou?r',
        text: 'colour'
      )
    }
  end

  def test_option4
    # skip
    expected = "color\n"
    assert_output(expected) {
      run_app!(
        pattern: 'colou?r',
        text: 'color'
      )
    }
  end

  def test_dot
    # skip
    expected = ["a\n", "a\n", "a\n", "b\n", "b\n", "b\n"].join
    assert_output(expected) {
      run_app!(
        pattern: '.',
        text: 'aaabbb'
      )
    }
  end

  def test_dot_star
    # skip
    expected = "aaabbb\n"
    assert_output(expected) {
      run_app!(
        pattern: '.*',
        text: 'aaabbb'
      )
    }
  end

  def test_slightly_more_complicated_regex
    # skip
    expected = "aaabbba\n"
    assert_output(expected) {
      run_app!(
        pattern: '(a|b)*(a|b)',
        text: 'aaabbba'
      )
    }
  end

  def test_multiline_input
    # skip
    expected = <<~HEREDOC
      aaa
      ccc
    HEREDOC

    text = <<~HEREDOC
      aaabb
      bbbccc
    HEREDOC

    assert_output(expected) {
      run_app!(
        pattern: 'aaa|ccc',
        text: text
      )
    }
  end

  def test_with_line_numbers_and_full_line_output
    # skip
    options = {
      line_numbers: true,
      only_matches: false
    }

    expected = <<~HEREDOC
      2: second line
    HEREDOC

    text = <<~HEREDOC
      first line
      second line
      third line
    HEREDOC

    assert_output(expected) {
      run_app!(
        pattern: 'second',
        text: text,
        opts: options
      )
    }
  end

  def test_with_full_line_output
    # skip

    options = {
      only_matches: false
    }

    expected = "second line\n"

    text = <<~HEREDOC
      first line
      second line
      third line
    HEREDOC

    assert_output(expected) {
      run_app!(
        pattern: 'second',
        text: text,
        opts: options
      )
    }
  end

  def test_with_line_numbers
    # skip
    options = { line_numbers: true }

    expected = <<~HEREDOC
      1:1: test
      1:11: test
    HEREDOC

    assert_output(expected) {
      run_app!(
        pattern: 'test',
        text: 'test abcd test abcd',
        opts: options
      )
    }
  end

  def test_coloring_on
    # skip
    options = { color: true }
    expected = "\e[4m\e[31mtest\e[0m\e[0m\n"
    # ^ to verify this is what we need:
    # `$ echo -e "\e[4m\e[31mtest\e[0m\e[0m\n"`
    # (the `-e` switch is to interpret escape characters)

    assert_output(expected) {
      run_app!(
        pattern: 'test',
        text: 'test',
        opts: options
      )
    }
  end

  def test_coloring_on2
    # skip
    options = {
      color: true,
      only_matches: false
    }
    expected = "somestuffand\e[4m\e[31mtest\e[0m\e[0mandmorestuff\n"

    assert_output(expected) {
      run_app!(
        pattern: 'test',
        text: 'somestuffandtestandmorestuff',
        opts: options
      )
    }
  end

  def teardown
    File.delete(@inp_path) if File.exist?(@inp_path)
    Dir.delete(@data_path)
  end
end
