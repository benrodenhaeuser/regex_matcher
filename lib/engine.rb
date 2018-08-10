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

    def initialize(pattern:, inp_path: nil, out_path: nil, user_options: {})
      @pattern  = pattern
      @inp_path = inp_path
      @out_path = out_path
      @opts     = DEFAULT_OPTIONS.merge(user_options)
    end

    def run
      automaton = Parser.new(@pattern).parse.to_automaton.to_dfa
      input     = @inp_path ? File.open(@inp_path, 'r') : $stdin.dup
      output    = @out_path ? File.open(@out_path, 'w') : $stdout.dup

      matcher = Matcher.new(
        automaton: automaton,
        output:    output,
        pad_width: pad_width,
        opts:      @opts
      )

      loop do
        break if input.eof?
        matcher.match(input.gets.chomp)
      end

      input.close
      output.close
    end

    private

    def pad_width
      return 3 unless @inp_path
      @pad_with ||= `wc -l #{@inp_path}`.split.first.length
    end
  end
end
