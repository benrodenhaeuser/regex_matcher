require_relative './named_file.rb'

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
      loop do
        path = files.shift
        break unless path
        @current = NamedFile.new(path)
        @current.file.each { |line| yield line }
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
