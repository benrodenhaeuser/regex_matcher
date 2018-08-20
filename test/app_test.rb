require 'minitest/autorun'

require_relative '../lib/rex_cli/application.rb'
require_relative '../lib/rex_cli/input.rb'
require_relative '../lib/rex_cli/defaults.rb'

class ApplicationTest < Minitest::Test
  def setup
    path_to_current_dir = File.expand_path(File.dirname(__FILE__))
    @data_path = File.join(path_to_current_dir, 'data')
    Dir.mkdir(@data_path) unless Dir.exist?(@data_path)
    @inp_path = File.join(@data_path, 'input.txt')
  end

  def run_app!(pattern:, text:, options: {})
    File.write(@inp_path, text)

    options = Rex::DEFAULT_OPTIONS.merge(options)

    Rex::Application.new(
      pattern: pattern,
      input:   Rex::Input.new([@inp_path], options),
      options: options
    ).run!
  end

  def test_concatenation_of_literals
    # skip
    options = {
      only_matches: true,
      line_numbers: false
    }
    expected = "test\ntest\n"
    assert_output(expected) {
      run_app!(
        pattern: 'test',
        text: 'test abcd test abcd',
        options: options
      )
    }
  end

  def test_one_match_mode
    # skip
    options = {
      global: false,
      only_matches: true,
      line_numbers: false
    }

    expected = "test\n"
    assert_output(expected) {
      run_app!(
        pattern: 'test',
        text: 'test abcd test abcd',
        options: options
      )
    }
  end

  def test_alternation
    # skip
    options = {
      only_matches: true,
      line_numbers: false
    }
    expected = "man\npark\n"
    assert_output(expected) {
      run_app!(
        pattern: 'man|park',
        text: 'a man is walking in the park.',
        options: options
      )
    }
  end

  def test_star
    # skip
    options = {
      only_matches: true,
      line_numbers: false
    }
    expected = <<~HEREDOC
      aaabbb



      ab
    HEREDOC
    # ^ we output empty matches. there are three here, each
    #   corresponding to one 'c', so we have three empty lines.

    assert_output(expected) {
      run_app!(
        pattern: '(a|b)*',
        text: 'aaabbbcccab',
        options: options
      )
    }
  end

  def test_option1
    # skip
    options = {
      only_matches: true,
      line_numbers: false
    }
    expected = "a\n"
    assert_output(expected) {
      run_app!(
        pattern: 'a?',
        text: 'a',
        options: options
      )
    }
  end

  def test_option2
    # skip
    options = {
      only_matches: true,
      line_numbers: false
    }
    expected = "\n"
    assert_output(expected) {
      run_app!(
        pattern: 'a?',
        text: 'b',
        options: options
      )
    }
  end

  def test_option3
    # skip
    options = {
      only_matches: true,
      line_numbers: false
    }
    expected = "colour\n"
    assert_output(expected) {
      run_app!(
        pattern: 'colou?r',
        text: 'colour',
        options: options
      )
    }
  end

  def test_option4
    # skip
    options = {
      only_matches: true,
      line_numbers: false
    }
    expected = "color\n"
    assert_output(expected) {
      run_app!(
        pattern: 'colou?r',
        text: 'color',
        options: options
      )
    }
  end

  def test_dot
    # skip
    options = {
      only_matches: true,
      line_numbers: false
    }
    expected = ["a\n", "a\n", "a\n", "b\n", "b\n", "b\n"].join
    assert_output(expected) {
      run_app!(
        pattern: '.',
        text: 'aaabbb',
        options: options
      )
    }
  end

  def test_dot_star
    # skip
    options = {
      only_matches: true,
      line_numbers: false
    }
    expected = "aaabbb\n"
    assert_output(expected) {
      run_app!(
        pattern: '.*',
        text: 'aaabbb',
        options: options
      )
    }
  end

  def test_slightly_more_complicated_regex
    # skip
    options = {
      only_matches: true,
      line_numbers: false
    }
    expected = "aaabbba\n"
    assert_output(expected) {
      run_app!(
        pattern: '(a|b)*(a|b)',
        text: 'aaabbba',
        options: options
      )
    }
  end

  def test_multiline_input
    # skip
    options = {
      only_matches: true,
      line_numbers: false
    }
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
        text: text,
        options: options
      )
    }
  end

  def test_with_line_numbers_and_full_line_output
    # skip
    options = {
      line_numbers: true
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
        options: options
      )
    }
  end

  def test_with_full_line_output
    # skip
    options = {
      only_matches: false,
      line_numbers: false
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
        options: options
      )
    }
  end

  def test_with_line_numbers
    # skip
    options = {
      line_numbers: true,
      only_matches: true
    }

    expected = <<~HEREDOC
      1:1: test
      1:11: test
    HEREDOC

    assert_output(expected) {
      run_app!(
        pattern: 'test',
        text: 'test abcd test abcd',
        options: options
      )
    }
  end

  def test_coloring_on
    # skip
    options = {
      color: true,
      only_matches: true,
      line_numbers: false
    }
    expected = "\e[4m\e[31mtest\e[0m\e[0m\n"
    # ^ to verify this is what we need:
    # `$ echo -e "\e[4m\e[31mtest\e[0m\e[0m\n"`
    # (the `-e` switch is to interpret escape characters)

    assert_output(expected) {
      run_app!(
        pattern: 'test',
        text: 'test',
        options: options
      )
    }
  end

  def test_coloring_on2
    # skip
    options = {
      color: true,
      line_numbers: false
    }
    expected = "somestuffand\e[4m\e[31mtest\e[0m\e[0mandmorestuff\n"

    assert_output(expected) {
      run_app!(
        pattern: 'test',
        text: 'somestuffandtestandmorestuff',
        options: options
      )
    }
  end

  def teardown
    File.delete(@inp_path) if File.exist?(@inp_path)
    Dir.delete(@data_path)
  end
end
