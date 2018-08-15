require_relative './engine.rb'

module Rex
  class Application
    DEFAULT_OPTIONS = {     # CLI options cheatsheet:
      line_numbers:  true,  # -d to disable line numbers
      whitespace:    false, # -w to prevent lstrip
      git:           false, # -g to enable git search
      all_lines:     false, # -a to enable all lines output
      only_matches:  false, # -m to enable only matches output
      global:        true,  # -o to enable one match per line
      highlight:     :auto, # -h to enforce highlighting
      file_names:    nil    # -f to enforce file name printing
    }.freeze

    def initialize(pattern:, input:, user_options: {})
      @pattern = pattern
      @input   = input
      @opts    = DEFAULT_OPTIONS.merge(user_options)

      @engine ||= Engine.new(@pattern, @opts)
    end

    def run
      process_options
      @input.each { |line| @engine.search(line.chomp).report!(@input, @opts) }
    end

    private

    def process_options
      file_list.replace(git_files) if @opts[:git]
      @opts[:file_names] ||= no_of_files > 1
    end

    def no_of_files
      @input.respond_to?(:argv) ? @input.argv.length : @input.files.length
    end

    def file_list
      @input.respond_to?(:argv) ? @input.argv : @input.files
    end

    def git_files
      `git ls-tree -r HEAD --name-only`.split("\n")
    end
  end
end
