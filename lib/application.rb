require_relative './engine.rb'

module Rex
  class Application
    DEFAULT_OPTIONS = {
      line_numbers:     true,
      global:           true,
      all_lines:        false,
      only_matches:     false,
      highlight:        :auto
    }.freeze

    def initialize(pattern:, input:, user_options: {})
      @pattern = pattern
      @input   = input
      @opts    = DEFAULT_OPTIONS.merge(user_options)
    end

    def run
      @opts[:print_file_names] = (@input.argv.size > 1 ? true : false)

      @input.each do |line|
        engine.search(line.chomp).report(@opts, @input)
        @input.lineno = 0 if @input.eof?
      end
    end

    private

    def engine
      @engine ||= Engine.new(@pattern, @opts)
    end
  end
end
