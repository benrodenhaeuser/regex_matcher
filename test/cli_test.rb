require 'minitest/autorun'

require_relative '../lib/rex_cli/application.rb'
require_relative '../lib/rex_cli/input.rb'

class CliTest < Minitest::Test
  def test_with_backticks
    # skip
    expected = "1: def def def\n"
    actual = `echo 'def def def' | bin/rex def`
    assert_equal(expected, actual)
  end
end
