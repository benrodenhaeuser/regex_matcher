require_relative './named_file.rb'
require_relative './application.rb'

module Rex
  class Input
    def self.[](*files)
      new(files)
    end

    attr_reader :files
    alias :argv :files
    # ^ Application instances need their input argument to respond to `argv`.

    def initialize(files)
      @files = files
    end

    def each
      return to_enum(:each) unless block_given?

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
