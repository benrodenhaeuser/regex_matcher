require_relative './engine.rb'

module Rex
  class Application
    DEFAULT_OPTIONS = {
      line_numbers: true,
      global:       true,
      all_lines:    false,
      only_matches: false,
      highlight:    :auto
    }.freeze

    def initialize(pattern:, inp_path: nil, out_path: nil, user_options: {})
      @pattern  = pattern
      @inp_path = inp_path
      @out_path = out_path
      @opts     = DEFAULT_OPTIONS.merge(user_options)
    end

    # BUG: broken: "if no input path is given, use stdin."

    def run
      @output = @out_path ? File.open(@out_path, 'w') : $stdout.dup

      if File.file?(@inp_path)
        process(@inp_path)
      else
        @opts[:print_file_names] = true
        entries = Dir.entries(@inp_path)
        files = entries.select do |entry|
          File.file?(File.join(@inp_path, entry))
        end

        files.each { |file| process(File.join(@inp_path, file)) }
      end

      @output.close
    end

    private

    def process(path)
      engine.reset

      @input = path ? File.open(path, 'r') : $stdin.dup

      until @input.eof?
        engine.search(@input.gets.chomp).report(@opts, @output, path)
      end

      @input.close
    end

    def engine
      @engine ||= Engine.new(@pattern, @opts)
    end
  end
end
