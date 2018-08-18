require_relative './application.rb'
require 'find'

module Rex
  class Input
    STDIN_PATH = '/dev/stdin'.freeze

    def self.[](*paths)
      new(paths)
    end

    attr_reader :paths
    attr_reader :current_file

    def initialize(paths)
      @paths = paths.empty? ? [STDIN_PATH] : paths
    end

    def each
      return to_enum(:each) unless block_given?

      Find.find(*paths) do |path|
        full_path = File.expand_path(path)

        if FileTest.directory?(path)
          if File.basename(full_path)[0] == '.'
            Find.prune
          else
            next
          end
        else
          @current_file = File.open(path, 'r')
          @current_file.each { |line| yield line }
        end
      end
    end
  end
end
