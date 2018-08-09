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
      only_matching_segments: false,
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
      file = File.open(@in_path)

      matcher = Matcher.new(
        automaton: automaton,
        line_count: line_count,
        out_path: @out_path,
        opts: @opts
      )

      until file.eof?
        matcher.match(file.gets.chomp)
      end

      file.close
    end

    private

    def line_count
      @line_count ||= `wc -l #{@in_path}`.split.first
    end
  end
end
