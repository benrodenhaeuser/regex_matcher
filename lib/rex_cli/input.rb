require_relative './application.rb'
require 'find'

module Rex
  class Input
    STDIN_PATH = '/dev/stdin'.freeze

    attr_reader :paths
    attr_reader :current_file

    def initialize(paths, options)
      @paths = paths
      @opts = options

      paths << STDIN_PATH if paths.empty?
    end

    def each
      return to_enum(:each) unless block_given?

      Find.find(*paths) do |path|
        first_letter = File.basename(File.expand_path(path))[0]

        if @opts[:skip_dot_files] && first_letter == '.'
          Find.prune
        end

        if @opts[:git] && `git check-ignore #{path}/` != ''
          Find.prune
        end

        next if FileTest.directory?(path)

        @current_file = File.open(path, 'r')
        @current_file.each { |line| yield line }
        @current_file.close
      end
    end
  end
end
