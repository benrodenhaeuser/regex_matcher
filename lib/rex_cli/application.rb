require_relative './engine.rb'

module Rex
  class Application
    DEFAULT_OPTIONS = {     # CLI options cheatsheet:
      line_numbers:  true,  # -d to disable line numbers
      git:           false, # -g to enable git search
      recursive:     false, # -r to enable recursive search
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

    private

    def setup
      @engine = Engine.new(@pattern, @opts)
      process_options
    end

    def process_options
      paths.replace(['.']) if @opts[:recursive] || @opts[:git]
      @opts[:file_names] ||= no_of_paths > 1 || @opts[:recursive] || @opts[:git]
    end

    def no_of_paths
      @input.paths.length
    end

    def paths
      @input.paths
    end
  end
end
