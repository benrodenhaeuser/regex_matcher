require 'minitest/autorun'

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
