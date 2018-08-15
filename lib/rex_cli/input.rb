require_relative './named_file.rb'
require_relative './application.rb'

module Rex
  class Input
    def self.[](*files)
      new(files)
    end

    attr_reader :files

    def initialize(files)
      @files = files
    end

    def each
      return to_enum(:each) unless block_given?

      loop do
        path = files.shift
        @current = NamedFile.new(path)
        @current.file.each { |line| yield line }
        break if files.empty?
      end
    end

    def filename
      @current.name
    end

    def file
      @current.file
    end
  end
end
