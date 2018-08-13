require_relative './engine.rb'

module Rex
  class Application
    DEFAULT_OPTIONS = {
      line_numbers:     true,
      whitespace:       false,
      git:              false,
      all_lines:        false,
      only_matches:     false,
      highlight:        :auto, # not accessible via CLI
      print_file_names: nil,   # not accessible via CLI
      global:           true   # affects the engine
    }.freeze

    def initialize(pattern:, input:, user_options: {})
      @pattern = pattern
      @input   = input
      @opts    = DEFAULT_OPTIONS.merge(user_options)
    end

    def run
      ARGV.replace(git_files) if @opts[:git]
      @opts[:print_file_names] ||= @input.argv.size > 1

      @input.each do |line|
        engine.search(line.chomp)
              .report(@opts, @input.file.lineno, @input.filename)
      end
    end

    private

    def engine
      @engine ||= Engine.new(@pattern, @opts)
    end

    def git_files
      `git ls-tree -r HEAD --name-only`.split("\n")
    end
  end
end
