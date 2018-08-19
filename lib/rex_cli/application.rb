require_relative './engine.rb'

module Rex
  class Application
    def initialize(pattern:, input:, options:)
      @pattern = pattern
      @input   = input
      @opts    = options

      @engine = Engine.new(@pattern, @opts)
      file_paths.replace(['.']) if @opts[:recursive]
      file_paths.replace(git_files) if @opts[:git]
      @opts[:file_names] ||= no_of_paths > 1 || @opts[:recursive] || @opts[:git]
    end

    def run!
      @input.each do |line|
        @engine.search(line.chomp).report!(@input, @opts)
      end
    end

    private

    def no_of_paths
      @input.paths.length
    end

    def file_paths
      @input.paths
    end

    def git_files
      `git ls-files`.lines.map(&:chomp)
    end
  end
end
