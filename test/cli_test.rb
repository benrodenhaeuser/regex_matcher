require 'minitest/autorun'

# git:            false, # `-g`
# recursive:      false, # `-r`
# global:         true,  # `-s`
# all_lines:      false, # `-a`
# only_matches:   false, # `-o`
# whitespace:     false, # `-w`
# skip_dot_files: true,  # (no flag)
# line_numbers:   nil,   # `-l ARG`
# color:          nil,   # `-c ARG`
# file_names:     nil    # `-f ARG`


require_relative '../lib/rex_cli/application.rb'
require_relative '../lib/rex_cli/input.rb'

class CliTest < Minitest::Test
  def test_simple_rex_search_works
    # skip
    expected = "def def def\n"
    actual = `echo 'def def def' | bin/rex def`
    assert_equal(expected, actual)
  end

  def test_git_option_produces_something_useable
    # skip
    actual = `bin/rex --git 'def | class'`
    expected = %w(application.rb input.rb result.rb def class initialize)
    expected.each do |str|
      assert(actual.include?(str))
    end
  end
end
