require_relative './parser.rb'
require_relative './automaton.rb'
require_relative './engine.rb'
require_relative './reporter.rb'

module Rex
  class Application
    DEFAULT_OPTIONS = {
      line_numbers:           true,
      one_match_per_line:     false,
      all_lines:              false,
      matching_segments_only: false
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

      engine = Engine.new(automaton, @opts[:one_match_per_line])

      reporter = Reporter.new(
        pad_width: pad_width,
        opts:      @opts,
        output:    output
      )

      loop do
        break if input.eof?
        reporter.report(engine.match(input.gets.chomp))
      end

      input.close
      output.close
    end

    private

    def pad_width
      return 1 unless @inp_path
      @pad_width ||= `wc -l #{@inp_path}`.split.first.length
    end
  end
end
