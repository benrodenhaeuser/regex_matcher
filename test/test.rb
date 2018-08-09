# require 'simplecov'
# SimpleCov.root ".."
# SimpleCov.start

require 'minitest/autorun'

require_relative '../lib/matcher.rb'

# how to test something that produces output rather than a string?
# we need to manipulate stdout, I think.

class MatcherTest < Minitest::Test

end
