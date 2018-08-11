require_relative './engine.rb'

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
      input  = @inp_path ? File.open(@inp_path, 'r') : $stdin.dup
      output = @out_path ? File.open(@out_path, 'w') : $stdout.dup
      engine = Engine.new(@pattern, !@opts[:one_match_per_line])

      loop do
        break if input.eof?
        engine.match(input.gets.chomp).report(@opts, output)
      end

      input.close
      output.close
    end

    def process_input

    end
  end
end
