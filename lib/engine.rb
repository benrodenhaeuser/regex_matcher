require_relative './string.rb'
require_relative './parser.rb'
require_relative './automaton.rb'
require_relative './matcher.rb'

module Rex
  class Engine
    DEFAULT_OPTIONS = {
      line_numbers:           true,
      global_matching:        true,
      non_matching_lines:     false,
      only_matching_segments: false
    }.freeze

    def initialize(pattern:, path:, substitution: nil, user_options: {})
      @pattern      = pattern
      @path         = path
      @substitution = substitution
      @opts         = DEFAULT_OPTIONS.merge(user_options)
    end

    def run
      automaton = Parser.new(@pattern).parse.to_automaton.to_dfa
      file = File.open(@path)
      matcher = Matcher.new(automaton, line_count, @opts)

      until file.eof?
        matcher.match(file.gets.chomp)
      end

      file.close
    end

    private

    def line_count
      @line_count ||= `wc -l #{@path}`.split.first
    end
  end
end
