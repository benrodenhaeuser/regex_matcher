require_relative './application.rb'
require 'find'

module Rex
  class Input
    STDIN_PATH = '/dev/stdin'.freeze

    attr_reader :paths
    attr_reader :current_file

    def initialize(paths, options)
      @paths = paths
      @options = options

      paths << STDIN_PATH if paths.empty?
    end

    def each
      return to_enum(:each) unless block_given?

      Find.find(*paths) do |path|
        absolute_path = File.expand_path(path)

        if FileTest.directory?(path)
          if File.basename(absolute_path)[0] == '.'
            Find.prune
          else
            next
          end
        else
          @current_file = File.open(path, 'r')
          @current_file.each { |line| yield line }
          @current_file.close
        end
      end
    end
  end
end
