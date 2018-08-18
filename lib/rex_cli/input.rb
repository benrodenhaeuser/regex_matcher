require_relative './named_file.rb'
require_relative './application.rb'

module Rex
  class Input
    def self.[](*paths)
      new(paths)
    end

    attr_reader :paths
    attr_reader :current_file

    def initialize(paths)
      # TODO: make '/dev/stdin' a constant
      @paths = paths.empty? ? ['/dev/stdin'] : paths
    end

    def each
      return to_enum(:each) unless block_given?

      loop do
        path = paths.shift
        @current_file = File.open(path, 'r')
        @current_file.each { |line| yield line }
        break if paths.empty?
      end
    end

    # def filename
    #   @current.path
    # end

    # def file
    #   @current.file
    # end
  end
end
