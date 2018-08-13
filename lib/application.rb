require_relative './engine.rb'

module Rex
  class Application
    DEFAULT_OPTIONS = {        # user options (CLI):
      line_numbers:     true,  # -d to disable line numbers
      whitespace:       false, # -w to prevent lstrip
      git:              false, # -g to enable git search
      all_lines:        false, # -a to enable all lines output
      only_matches:     false, # -m to enable only matches output
      global:           true,  # -o to enable one match per line
      highlight:        :auto, # -h to enforce highlighting
      print_file_names: nil    # -f to enforce file name printing
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
              .report(@input, @opts)
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
