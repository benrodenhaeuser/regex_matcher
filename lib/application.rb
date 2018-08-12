require_relative './engine.rb'

module Rex
  class Application
    DEFAULT_OPTIONS = {
      line_numbers: true,
      global:       true,
      all_lines:    false,
      only_matches: false
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

      until input.eof?
        engine.search(input.gets.chomp).report(@opts, output)
      end

      input.close
      output.close
    end

    private

    def engine
      @engine ||= Engine.new(@pattern, @opts)
    end
  end
end
