require_relative './string.rb'
require_relative './parser.rb'
require_relative './automaton.rb'
require_relative './matcher.rb'

module Rex
  class Engine
    DEFAULT_OPTIONS = {
      line_numbers:           true,
      one_match_per_line:     false,
      all_lines:              false,
      matching_segments_only: false,
      substitution:           nil
    }.freeze

    def initialize(pattern:, in_path:, out_path: nil, user_options: {})
      @pattern  = pattern
      @in_path  = in_path
      @out_path = out_path
      @opts     = DEFAULT_OPTIONS.merge(user_options)
    end

    def run
      automaton = Parser.new(@pattern).parse.to_automaton.to_dfa
      input = File.open(@in_path)
      output = (@out_path ? File.open(@out_path, 'w') : $stdout.dup)

      matcher = Matcher.new(
        automaton:  automaton,
        line_count: line_count,
        output:     output,
        opts:       @opts
      )

      until input.eof?
        matcher.match(input.gets.chomp)
      end

      input.close
      output.close
    end

    private

    def line_count
      @line_count ||= `wc -l #{@in_path}`.split.first
    end
  end
end
