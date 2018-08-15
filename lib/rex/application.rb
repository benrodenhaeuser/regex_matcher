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

      setup
    end

    def report!
      @input.each do |line|
        @engine.search(line.chomp).report!(@input, @opts)
      end
    end

    def report
      @input.each.with_object('') do |line, the_report|
        line_report = @engine.search(line.chomp).report(@input, @opts)
        the_report << "#{line_report}\n" unless line_report.nil?
      end
    end

    private

    def setup
      @engine ||= Engine.new(@pattern, @opts)
      process_options
    end

    def process_options
      file_list.replace(git_files) if @opts[:git]
      @opts[:file_names] ||= no_of_files > 1
    end

    def no_of_files
      @input.argv.length
    end

    def file_list
      @input.argv
    end

    def git_files
      `git ls-files`.split("\n")
    end
  end
end
