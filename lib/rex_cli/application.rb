require_relative './engine.rb'

module Rex
  class Application
    DEFAULT_OPTIONS = {     # CLI options cheatsheet:
      line_numbers:  true,  # -d to disable line numbers
      git:           false, # -g to enable git search
      global:        true,  # -o to enable one match per line
      all_lines:     false, # -a to enable all lines output
      only_matches:  false, # -m to enable only matches output
      whitespace:    false, # -w to prevent lstrip
      highlight:     :auto, # -H to enforce highlighting,
                            # -h to disable highlighting
      file_names:    nil    # -f to enforce file name printing
    }.freeze

    def initialize(pattern:, input:, user_options: {})
      @pattern = pattern
      @input   = input
      @opts    = DEFAULT_OPTIONS.merge(user_options)

      setup
    end

    def run!
      @input.each do |line|
        @engine.search(line.chomp).report!(@input, @opts)
      end
    end

    # TODO: do we even want this?
    # def run
    #   @input.each.with_object('') do |line, the_report|
    #     line_report = @engine.search(line.chomp).report(@input, @opts)
    #     the_report << "#{line_report}\n" unless line_report.nil?
    #   end
    # end

    private

    def setup
      @engine = Engine.new(@pattern, @opts)
      process_options
    end

    def process_options
      paths.replace(git_files) if @opts[:git]
      @opts[:file_names] ||= no_of_paths > 1
      # TODO: this might be a problem if allow directory paths here ...
      # how are we going to know whether we have several files, or just one?
      # solution: if we have several paths, or we are doing a git or dir
      # search, then we want file names (even though there is an edge case
      # where we are still searching only one file).
    end

    def no_of_paths
      @input.paths.length
    end

    def paths
      @input.paths
    end

    def git_files
      `git ls-files`.split("\n")
    end
  end
end
